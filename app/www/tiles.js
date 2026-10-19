// Green tiles: jump to the next tile after typing a letter, and back to the
// previous one on Backspace when the current tile is empty.
document.addEventListener("input", function (e) {
  const tile = e.target.closest(".tile");
  if (!tile || tile.value.length < 1) return;
  const next = document.getElementById("green_" + (Number(tile.id.split("_")[1]) + 1));
  if (next) next.focus(), next.select();
});

document.addEventListener("keydown", function (e) {
  const tile = e.target.closest(".tile");
  if (!tile || e.key !== "Backspace" || tile.value !== "") return;
  const prev = document.getElementById("green_" + (Number(tile.id.split("_")[1]) - 1));
  if (prev) prev.focus();
});
