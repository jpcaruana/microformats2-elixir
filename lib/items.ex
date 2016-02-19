defmodule Microformats2.Items do
  @root_level ["h-adr", "h-card", "h-entry", "h-event", "h-feed",
               "h-geo", "h-item", "h-listing", "h-product",
               "h-recipe", "h-resume", "h-review", "h-review-aggregate"]

  def parse(nodes, items \\ [])
  def parse([head | tail], items) do
    nitems = if not is_bitstring(head) do
      parse(head, items)
    else
      items
    end

    parse(tail, nitems)
  end

  def parse([], items) do
    items
  end

  def parse(root, items) do
    classes = Microformats2.attr_list(root)
    root_classes = Set.intersection(Enum.into(classes, HashSet.new),
                                    Enum.into(@root_level, HashSet.new)) |> Enum.sort

    {_, _, children} = root

    if not Enum.empty?(root_classes) do
      entry = parse_sub(children, %{type: root_classes,
                                    properties: %{}}) |> Microformats2.Items.ImpliedProperties.parse(root)

      items ++ [entry]

    else
      parse(children, items)
    end
  end

  defp parse_sub([], item), do: item
  defp parse_sub([child | children], item) when is_bitstring(child), do: parse_sub(children, item)
  defp parse_sub([child | children], item) do
    props = Microformats2.attr_list(child) |>
      Enum.filter(fn("p-" <> _) -> true
        ("u-" <> _) -> true
        ("dt-" <> _) -> true
        ("e-" <> _) -> true
        (_) -> false end) |>
      Enum.reduce(item[:properties], fn(class, acc) ->
        prop = parse_prop(class, child)
        key = strip_prefix(class) |> to_key |> String.to_atom
        val = if acc[key] != nil, do: acc[key], else: []
        Map.put(acc, key, val ++ [prop])
      end)

    parse_sub(children, Map.put(item, :properties, props))
  end

  defp parse_prop("p-" <> _, child) do
    # TODO value pattern parsing
    {elem, _, _} = child
    title = Floki.attribute(child, "title") |> List.first
    alt   = Floki.attribute(child, "alt")   |> List.first

    cond do
      elem == "abbr" and not Microformats2.blank?(title) ->
        title
      elem == "img" and not Microformats2.blank?(alt) ->
        alt
      true ->
        text_content(child) |> String.strip
    end
  end


  defp parse_prop("u-" <> _, child = {elem, _, _}) do
    href   = Floki.attribute(child, "href")   |> List.first
    src    = Floki.attribute(child, "src")    |> List.first
    data   = Floki.attribute(child, "data")   |> List.first
    poster = Floki.attribute(child, "poster") |> List.first
    title  = Floki.attribute(child, "title")  |> List.first
    value  = Floki.attribute(child, "value")  |> List.first
    
    cond do
      Enum.member?(["a", "area"], elem) and not Microformats2.blank?(href) ->
        href
      Enum.member?(["img", "audio", "video", "source"], elem) and not Microformats2.blank?(src) ->
        src
      elem == "object" and not Microformats2.blank?(data) ->
        data
      elem == "video" and not Microformats2.blank?(poster) ->
        poster
        # TODO value-class-pattern at this position
      elem == "abbr" and not Microformats2.blank?(title) ->
        title
      Enum.member?(["data", "input"], elem) and not Microformats2.blank?(value) ->
        value
      true ->
        text_content(child) |> String.strip
    end
  end

  defp parse_prop("dt-" <> _, child = {elem, _, _}) do
    dt = Floki.attribute(child, "datetime")
    title = Floki.attribute(child, "title")
    value = Floki.attribute(child, "value")

    cond do
      Enum.member?(["time", "ins", "del"], elem) and not Microformats2.blank?(dt) ->
        dt
      elem == "abbr" and not Microformats2.blank?(title) ->
        title
      Enum.member?(["data", "input"], elem) and not Microformats2.blank?(value) ->
        value
      true ->
        text_content(child) |> String.strip
    end
  end

  defp parse_prop("e-" <> _, child) do
    %{html: Floki.raw_html(child),
      text: Floki.text(child)}
  end

  defp parse_prop(_, _), do: nil





  defp strip_prefix("p-" <> rest) do
    rest
  end
  defp strip_prefix("u-" <> rest) do
    rest
  end
  defp strip_prefix("dt-" <> rest) do
    rest
  end
  defp strip_prefix("e-" <> rest) do
    rest
  end
  defp strip_prefix(rest) do
    rest
  end

  def text_content(child, text \\ "")

  def text_content(child = {elem, _, children}, text) do
    txt = if elem == "img" do
      alt = Floki.attribute(child, "alt")
      if alt != nil and alt != "" do
        alt
      else
        Floki.attribute(child, "src")
      end
    else
      ""
    end

    Enum.reduce(children, text <> txt, fn(child, acc) ->
      text_content(child, acc)
    end)
  end

  def text_content(child, text) when is_bitstring(child) do
    text <> child
  end

  defp to_key(str) do
    String.replace(str, ~r/[-]/, "_")
  end
end