# Input Alert - patch notes

## 1.1.3.0 (2026-11-18)
- GIANTS TestRunner fixes: removed pcall around getSelectedProduction, changelog added to the modDesc
  description (en/de), duplicate German title removed. GitHub link added to the description.

## 1.1.2.0 (2026-11-18)
- INCOMING MATERIALS: only materials used by a switched-on product are highlighted (e.g. Sugar Beet Cut at
  BGA Nord is no longer highlighted while that product is off).

## 1.1.1.0 (2026-11-18)
- Fix: red bands also appeared across the PRODUCTS list when a product has the same name as a low material
  (e.g. Manure, Sugar Beet Cut). Only storage rows (the ones showing "level / capacity") in the right-hand column,
  right of the PRODUCTS list, are highlighted now.

## 1.1.0.0 (2026-11-18)
- New: INCOMING MATERIALS list (top of the right panel). Every input material at 10% of its capacity or less gets a
  soft red highlight over its row, whatever product is selected. Recipe status boxes unchanged.

## 1.0.2.0 (2026-11-18)
- Fix: no boxes showed on the recipe (log: "no recipe rows found"). Recipe rows are now matched by the input's name at
  the end of the text, whatever the amount looks like. If rows are still not found, the log lists the texts it saw.

## 1.0.1.0 (2026-11-18)
- Fix: status boxes showed in the INCOMING MATERIALS list (every stored material, used or not) instead of the
  recipe. Boxes now only go on the input rows under "RECIPE: ...".

## 1.0.0.0 (2026-11-18)
- First build. Production Chains menu: every recipe input gets a status box
  (green tick = 10+ cycles in storage, yellow plus = 2-10, red X = under 2 / empty). Read only, no hotkeys.
