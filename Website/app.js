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

const dropZone = document.querySelector("#drop-zone");
const fileInput = document.querySelector("#demo-file");
const chooseFile = document.querySelector("#choose-file");
const demoEmpty = document.querySelector("#demo-empty");
const demoResult = document.querySelector("#demo-result");
const demoPreview = document.querySelector("#demo-preview");
const demoName = document.querySelector("#demo-name");
const demoSize = document.querySelector("#demo-size");
const demoStatus = document.querySelector("#demo-status");
let selectedDemoFormat = "JPG";
const demoSteps = document.querySelectorAll(".demo-steps span");
const setDemoStep = (step) => {
  demoSteps.forEach((item, index) => item.classList.toggle("active", index === step - 1));
};
const showDemoFile = (file) => {
  if (!file || !file.type.startsWith("image/")) return;
  const reader = new FileReader();
  reader.addEventListener("load", () => {
    demoPreview.src = reader.result;
    demoName.textContent = file.name;
    demoSize.textContent = `${(file.size / 1024 / 1024).toFixed(2)} MB · Ready to choose an output`;
    demoEmpty.hidden = true;
    demoResult.hidden = false;
    setDemoStep(2);
  }, { once: true });
  reader.readAsDataURL(file);
};
chooseFile.addEventListener("click", (event) => { event.stopPropagation(); fileInput.click(); });
dropZone.addEventListener("click", () => { if (demoResult.hidden) fileInput.click(); });
fileInput.addEventListener("change", () => showDemoFile(fileInput.files[0]));
["dragenter", "dragover"].forEach((eventName) => dropZone.addEventListener(eventName, (event) => { event.preventDefault(); dropZone.classList.add("is-dragging"); }));
["dragleave", "drop"].forEach((eventName) => dropZone.addEventListener(eventName, (event) => { event.preventDefault(); dropZone.classList.remove("is-dragging"); }));
dropZone.addEventListener("drop", (event) => showDemoFile(event.dataTransfer.files[0]));
document.querySelector(".demo-reset").addEventListener("click", (event) => { event.stopPropagation(); fileInput.value = ""; demoResult.hidden = true; demoEmpty.hidden = false; demoStatus.textContent = ""; setDemoStep(1); });
document.querySelectorAll(".demo-format").forEach((button) => button.addEventListener("click", (event) => {
  event.stopPropagation();
  document.querySelectorAll(".demo-format").forEach((item) => item.classList.remove("is-active"));
  button.classList.add("is-active");
  selectedDemoFormat = button.textContent;
  demoStatus.textContent = "";
  setDemoStep(2);
}));
document.querySelector(".demo-convert").addEventListener("click", (event) => {
  event.stopPropagation();
  if (!demoPreview.src) return;
  const image = new Image();
  image.onload = () => {
    const canvas = document.createElement("canvas");
    canvas.width = image.naturalWidth;
    canvas.height = image.naturalHeight;
    canvas.getContext("2d").drawImage(image, 0, 0);
    const mime = selectedDemoFormat === "JPG" ? "image/jpeg" : `image/${selectedDemoFormat.toLowerCase()}`;
    canvas.toBlob((blob) => {
      if (!blob) {
        demoStatus.textContent = "This image could not be converted.";
        return;
      }
      const link = document.createElement("a");
      link.href = URL.createObjectURL(blob);
      link.download = `${demoName.textContent.replace(/\.[^.]+$/, "") || "donut-image"}.${selectedDemoFormat.toLowerCase()}`;
      link.click();
      window.setTimeout(() => URL.revokeObjectURL(link.href), 1000);
      demoStatus.textContent = `Done — your ${selectedDemoFormat} download is starting.`;
      setDemoStep(3);
    }, mime, selectedDemoFormat === "JPG" ? 0.96 : undefined);
  };
  image.src = demoPreview.src;
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
