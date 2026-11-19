[ .. | objects | select(has("columns") and has("data")) ] as $blocks
| $blocks[0] as $block
| ($block.columns | map(if . == null then "" else tostring end) | @csv),
  ($block.data[]? | map(if . == null then "" else tostring end) | @csv)
