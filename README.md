# tIR — Transient Infrared Spectroscopy Analysis App

A MATLAB GUI for loading, processing, and visualising transient IR pump-probe data.

---

## Requirements

- MATLAB R2022a or newer
- No additional toolboxes required

---

## Quick Start

1. **Open MATLAB** and `cd` into the `V5/` folder.
2. Run `tIR_app` in the Command Window — the GUI opens automatically.
3. The app auto-loads `example_config.m` on startup. Edit that file first (see below), or use **Load Config** to point to your own.
4. Click **▶ Run** to process and plot.

---

## Configuring for Your Data

Edit `example_config.m` (or copy it) and set these key fields:

| Field | What it is |
|---|---|
| `data_dir` | Folder containing your scan `.txt` files |
| `cal_file` | Calibration file (pixel → wavenumber). Pre-made files are in `cailbration/` |
| `probe_file` | Probe reference `.txt`; set `'none'` to skip normalisation |
| `root_name` | Filename prefix of your scan (e.g. `'50nJ_time_scan_01_Row0'`) |
| `time_zero` | Scanner position (fs) of pump-probe overlap |
| `time_unit` | `'fs'` or `'ps'` — sets all axis labels |
| `pixel_region` | `'top'`, `'bottom'`, or `'all'` |

> **Finding `time_zero`:** Run once with `time_zero = 0`, read the overlap peak from the Projection tab, then set the value and re-run.

---

## GUI Overview

| Tab | What you see |
|---|---|
| ① Projection | Integrated signal vs time — use this to find `time_zero` |
| ② Raw | 2D contour of raw ΔA data |
| ③ Normalised | Normalised 2D contour + wavenumber-slice slider |
| ④ Spectral Slices | ΔA spectra at selected time delays (`slice_times`) |
| ⑤ Time Slices | Kinetic traces at selected wavenumbers (`slice_wavenumbers`) |

**Advanced settings** (⚙ button): contour levels, colormap, font size, line widths, file column indices.

**Export CSV**: saves the normalised 2D data with the time axis in display units.

---

## Folder Structure

```
V5/
├── tIR_app.m               # Launch this
├── tIRConfig.m             # Config class (do not edit)
├── example_config.m        # Edit this for your experiment
├── @SpectroscopyBase/      # Core data processing
├── @tIRDataset/            # Dataset class
├── utils/                  # redblue colormap, wl2wn
├── cailbration/            # Pixel-to-wavenumber calibration files
│   ├── center_3200nm.txt
│   ├── center_3300nm.txt
│   └── center_3500nm.txt
└── test_data/              # Example dataset
```

---

## Test Data

A sample dataset is included in `test_data/`. To run it:

1. Open `example_config.m`
2. Set `data_dir` to the `test_data/` subfolder path
3. Set `cal_file` to one of the files in `cailbration/`
4. Run the app
