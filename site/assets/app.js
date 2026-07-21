(() => {
  const page = document.body;
  const overlay = document.getElementById("entry-overlay");
  const artwork = document.getElementById("line-art");
  const hero = document.querySelector(".hero");
  let revealed = false;

  function reveal() {
    if (revealed) return;
    revealed = true;
    page.classList.remove("site-loading");
    page.classList.add("site-ready");
    hero?.setAttribute("aria-busy", "false");
    overlay?.classList.add("is-hidden");
  }

  if (artwork?.complete && artwork.naturalWidth > 0) {
    requestAnimationFrame(reveal);
  } else {
    artwork?.addEventListener("load", reveal, { once: true });
    artwork?.addEventListener("error", reveal, { once: true });
    window.setTimeout(reveal, 6000);
  }
})();

