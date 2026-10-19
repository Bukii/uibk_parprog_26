#!/usr/bin/env python3
"""Generate figures from the laptop benchmark table."""

from pathlib import Path
import re

import matplotlib.pyplot as plt
import numpy as np


LOG_PATH = Path(__file__).with_name("times_laptop.log")
OUTPUT_DIR = LOG_PATH.parent
THREADS = np.arange(1, 9)
FAMILIES = ("fast", "medium", "slow")


def read_times(path: Path) -> dict[str, np.ndarray]:
    """Read executable rows from the pipe-delimited timing table."""
    pattern = re.compile(r"^([a-z]+_(?:def|o1|o2|o3|ofast))\s+\|\s*(.*)$")
    measurements: dict[str, np.ndarray] = {}

    for line in path.read_text().splitlines():
        match = pattern.match(line)
        if match:
            values = [float(value.strip()) for value in match.group(2).split("|")]
            if len(values) != len(THREADS):
                raise ValueError(f"Expected 8 measurements for {match.group(1)}")
            measurements[match.group(1)] = np.array(values)

    if not measurements:
        raise ValueError(f"No timing rows found in {path}")
    return measurements


def plot_execution_times(measurements: dict[str, np.ndarray]) -> None:
    figure, axes = plt.subplots(1, 3, figsize=(15, 4.8), sharex=True)
    colors = {"def": "#1f4e79", "o1": "#2a9d8f", "o2": "#e9c46a", "o3": "#f4a261", "ofast": "#e76f51"}

    for axis, family in zip(axes, FAMILIES):
        for optimization in colors:
            name = f"{family}_{optimization}"
            axis.plot(THREADS, measurements[name], marker="o", linewidth=1.8,
                      markersize=4, label=optimization)
        axis.set_title(f"{family.capitalize()} implementation")
        axis.set_xlabel("OpenMP threads [count]")
        axis.set_ylabel("Execution time [s]")
        axis.set_xticks(THREADS)
        axis.set_ylim(bottom=0)
        axis.grid(axis="y", alpha=0.25)
    axes[-1].legend(title="Compiler flag", loc="upper left", fontsize=8)
    figure.suptitle("Laptop benchmark: execution time by thread count", fontweight="bold")
    figure.tight_layout()
    figure.savefig(OUTPUT_DIR / "execution_times.png", dpi=180, bbox_inches="tight")
    plt.close(figure)


def plot_speedups(measurements: dict[str, np.ndarray]) -> None:
    figure, axes = plt.subplots(1, 3, figsize=(15, 4.8), sharex=True)
    colors = {"def": "#1f4e79", "o1": "#2a9d8f", "o2": "#e9c46a", "o3": "#f4a261", "ofast": "#e76f51"}

    for axis, family in zip(axes, FAMILIES):
        for optimization in colors:
            name = f"{family}_{optimization}"
            baseline = measurements[name][0]
            speedup = np.divide(
                baseline,
                measurements[name],
                out=np.full(8, np.nan),
                where=(baseline > 0) & (measurements[name] > 0),
            )
            axis.plot(THREADS, speedup, marker="o", linewidth=1.8,
                      markersize=4, label=optimization)
        axis.plot(THREADS, THREADS, linestyle="--", color="#555555", linewidth=1,
                  label="ideal linear" if family == FAMILIES[0] else None)
        axis.set_title(f"{family.capitalize()} implementation")
        axis.set_xlabel("OpenMP threads [count]")
        axis.set_ylabel("Speedup [x]")
        axis.set_xticks(THREADS)
        axis.set_ylim(bottom=0)
        axis.grid(axis="y", alpha=0.25)
    axes[-1].legend(title="Compiler flag", loc="upper left", fontsize=8)
    figure.suptitle("Laptop benchmark: speedup relative to one thread", fontweight="bold")
    figure.tight_layout()
    figure.savefig(OUTPUT_DIR / "speedups.png", dpi=180, bbox_inches="tight")
    plt.close(figure)


def plot_heatmap(measurements: dict[str, np.ndarray]) -> None:
    names = list(measurements)
    values = np.array([measurements[name] for name in names])
    color_values = np.maximum(values, 1e-5)

    figure, axis = plt.subplots(figsize=(10, 6.5))
    image = axis.imshow(color_values, aspect="auto", cmap="YlOrRd", norm="log")
    axis.set_xticks(np.arange(8), THREADS)
    axis.set_yticks(np.arange(len(names)), names)
    axis.set_xlabel("OpenMP threads [count]")
    axis.set_ylabel("Executable")
    axis.set_title("Laptop benchmark: execution-time heatmap (log colour scale)", fontweight="bold")
    colorbar = figure.colorbar(image, ax=axis)
    colorbar.set_label("Execution time [s]")
    figure.tight_layout()
    figure.savefig(OUTPUT_DIR / "timing_heatmap.png", dpi=180, bbox_inches="tight")
    plt.close(figure)


def main() -> None:
    measurements = read_times(LOG_PATH)
    plot_execution_times(measurements)
    plot_speedups(measurements)
    plot_heatmap(measurements)
    print(f"Generated charts in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()