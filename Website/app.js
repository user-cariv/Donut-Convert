const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const nav = document.querySelector(".nav");
const updateScrollDepth = () => {
  const y = window.scrollY;
  nav.classList.toggle("is-scrolled", y > 32);
  if (!reduceMotion) {
    document.documentElement.style.setProperty("--ambient-one-y", `${y * 0.08}px`);
    document.documentElement.style.setProperty("--ambient-two-y", `${y * -0.05}px`);
  }
};
window.addEventListener("scroll", updateScrollDepth, { passive: true });
updateScrollDepth();

document.querySelectorAll('a[href^="#"]:not([data-open-download])').forEach((link) => {
  link.addEventListener("click", (event) => {
    const target = document.querySelector(link.getAttribute("href"));
    if (!target) return;
    event.preventDefault();
    target.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "start" });
    link.blur();
  });
});

const themeToggle = document.querySelector(".theme-toggle");
const storedTheme = localStorage.getItem("donut-theme");
if (storedTheme === "dark") document.body.classList.add("dark-mode");
themeToggle.addEventListener("click", () => {
  document.body.classList.toggle("dark-mode");
  localStorage.setItem("donut-theme", document.body.classList.contains("dark-mode") ? "dark" : "light");
});

const downloadModal = document.querySelector("#download-modal");
const platformName = /Mac|iPhone|iPad/.test(navigator.platform) ? "macOS" : "Windows";
document.querySelector(".modal-intro").textContent = `${platformName} detected. Pick your platform to get started — or choose the other build anytime.`;
const openDownload = () => {
  downloadModal.hidden = false;
  document.body.classList.add("modal-open");
  downloadModal.querySelector(".modal-close").focus();
};
const closeDownload = () => {
  downloadModal.hidden = true;
  document.body.classList.remove("modal-open");
};
document.querySelectorAll("[data-open-download]").forEach((trigger) => {
  trigger.addEventListener("click", (event) => {
    event.preventDefault();
    openDownload();
  });
});
document.querySelectorAll("[data-close-download]").forEach((trigger) => {
  trigger.addEventListener("click", closeDownload);
});
document.querySelectorAll("a.download-choice, a.platform-option").forEach((link) => {
  link.addEventListener("click", () => {
    const toast = document.createElement("div");
    toast.className = "download-toast";
    toast.textContent = "Your Donut download is starting…";
    document.body.append(toast);
    window.setTimeout(() => toast.remove(), 3200);
  });
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && !downloadModal.hidden) closeDownload();
});

const progress = document.querySelector(".scroll-progress");
const updateProgress = () => {
  const max = document.documentElement.scrollHeight - window.innerHeight;
  progress.style.width = `${max > 0 ? (window.scrollY / max) * 100 : 0}%`;
};
window.addEventListener("scroll", updateProgress, { passive: true });
updateProgress();

document.querySelectorAll(".format-tile").forEach((tile) => {
  tile.addEventListener("click", () => {
    document.querySelectorAll(".format-tile").forEach((item) => item.classList.remove("is-selected"));
    tile.classList.add("is-selected");
    document.querySelector("#selected-format").textContent = tile.dataset.format;
    document.querySelector("#format-description").textContent = tile.dataset.description;
  });
});

if (!reduceMotion && "IntersectionObserver" in window) {
  const revealItems = document.querySelectorAll(".section, .proof, .download-panel");
  revealItems.forEach((item) => item.classList.add("reveal"));
  const observer = new IntersectionObserver((entries, currentObserver) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("is-visible");
      currentObserver.unobserve(entry.target);
    });
  }, { threshold: 0.12 });
  revealItems.forEach((item) => observer.observe(item));

  document.querySelectorAll(".steps .glass-card, .use-grid .use-card, .format-grid .format-tile").forEach((item, index) => {
    item.style.setProperty("--reveal-delay", `${Math.min(index * 70, 280)}ms`);
  });
}

document.querySelectorAll("img[data-fallback]").forEach((image) => {
  image.addEventListener("error", () => {
    image.src = image.dataset.fallback;
    image.alt = "Donut logo";
  }, { once: true });
});

if (!reduceMotion) {
  const art = document.querySelector(".hero-art");
  window.addEventListener("pointermove", (event) => {
    const x = (event.clientX / window.innerWidth - 0.5) * 10;
    const y = (event.clientY / window.innerHeight - 0.5) * 10;
    art.style.transform = `translate(${x}px, ${y}px)`;
  }, { passive: true });
}
