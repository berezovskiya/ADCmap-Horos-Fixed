# ADCmap for Horos - v3.0 "Sudden Awakening"

![Version](https://img.shields.io/badge/version-3.0-blue.svg)
![macOS](https://img.shields.io/badge/macOS-10.15+-green.svg)
![Horos](https://img.shields.io/badge/Horos-3.3.6+-brightgreen.svg)
![License](https://img.shields.io/badge/license-Open%20Source-orange.svg)

**Stable ADCmap plugin for Horos DICOM Viewer with critical crash fixes for modern macOS**

## 🎯 What is this?

ADCmap is a plugin for [Horos DICOM Viewer](https://horosproject.org/) that calculates Apparent Diffusion Coefficient (ADC) from MRI DICOM images.

This fork ports the original OsiriX plugin ADCMap (by Dr. Brian Hargreaves) to **Horos** and fixes critical crashes that occurred on modern macOS versions.

## ✨ Features

- 📊 Quick and easy ADC calculation from DICOM images
- 🔬 IVIM fitting (fast and biexponential)
- 🖼️ Synthetic image generation
- 🏥 Support for major MRI vendor file headers
- 📈 Graph plotting and data visualization
- 💾 Export results to PDF and TXT formats

## 🔧 What's Fixed in v3.0

### Critical Crash Fix
**Problem:** Plugin crashed on macOS 10.15+ with error:
```
Crashing on exception: Invalid parameter not satisfying: !isnan(newSize.width)
Exception Type: EXC_BAD_INSTRUCTION (SIGILL)
Application Specific Backtrace:
...
5 ADCMap 0x0000000112038f45 -[ADC_ToolGraph drawXAxis::::::] + 1221
```

**Root Cause:** The `drawXAxis` method in `ADC_ToolGraph` class was passing NaN (Not a Number) values to `setFrameSize:` when dividing by zero occurred (when `timeX[maxX] == timeX[minX]`).

**Solution:** 
- ✅ Added NaN and infinity checks before all mathematical operations
- ✅ Added size validation before `setFrameSize:` calls
- ✅ Implemented safe default values
- ✅ Enhanced logging for diagnostics

The plugin now works correctly on all macOS versions 10.15 (Catalina) and newer, including the latest macOS 15 (Sequoia).

## 📋 System Requirements

- **macOS:** 10.15 (Catalina) or newer
- **Horos:** 3.3.6 or newer (4.0+ recommended)
- **Processor:** Intel or Apple Silicon (M1/M2/M3/M4)

## 🚀 Installation

### Option 1: Pre-built Plugin (Recommended)

1. Download the latest release from [Releases](../../releases)
2. Unzip the downloaded file
3. Copy `ADCmap.plugin` to:
   ```
   ~/Library/Application Support/Horos/Plugins/
   ```
4. Restart Horos

### Option 2: Build from Source

1. Clone this repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ADCmap-Horos.git
   cd ADCmap-Horos
   ```

2. Open the project in Xcode:
   ```bash
   open ADCmap.xcodeproj
   ```

3. Build the project (⌘B) or create an archive:
   ```
   Product → Build for → Running
   ```

4. Copy the built plugin to Horos plugins directory:
   ```bash
   cp -r build/Release/ADCmap.plugin ~/Library/Application\ Support/Horos/Plugins/
   ```

5. Restart Horos

## 📖 Usage

1. Open a DWI (Diffusion Weighted Imaging) series in Horos
2. Select **Plugins → Image Filters → ADCmap** from the menu
3. The ADCmap window will open with your data
4. Configure your analysis parameters
5. View the calculated ADC maps and graphs
6. Export results if needed

## 🐛 Bug Reports

If you encounter any issues, please [open an issue](../../issues) with:
- macOS version
- Horos version
- Steps to reproduce
- Crash logs (if applicable)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📜 Version History

### v3.0 "Sudden Awakening" (Current)
- Fixed critical NaN crash in `drawXAxis` and `drawYAxis` methods
- Added comprehensive validation for mathematical operations
- Improved stability on macOS 10.15+
- Enhanced error logging
- Updated build number to 300

### v2.0 (Previous)
- Initial Horos port from OsiriX

## 🙏 Credits

- **Original Author:** Dr. Brian Hargreaves (OsiriX ADCMap plugin)
- **Horos Port:** Andrea Brizola ([original repository](https://github.com/brizolara/ADCmap.hpg))
- **v3.0 Fixes & Maintenance:** This fork

## ⚠️ Disclaimer

This code was developed for quick/easy ADC calculation from DICOM images. The developer is not an expert in DWI (Diffusion Weighted Imaging), so comments and feedback are welcome.

This software is provided "as is" without warranty of any kind. Use at your own risk. Always verify results with clinical standards.

## 📄 License

Open Source - see original repository for details

---

**Note:** This is a medical imaging tool. Always validate results and consult with qualified medical professionals for clinical decisions.
