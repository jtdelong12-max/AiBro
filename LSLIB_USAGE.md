# LSLib Installation

LSLib has been successfully installed on your system!

## What is LSLib?

LSLib is a comprehensive toolkit for working with Baldur's Gate 3 and Divinity: Original Sin 2 files. It includes:
- **Divine.exe** - Command-line tool for pak/lsx/lsf/gr2 conversion
- **ConverterApp** - GUI tool for file conversion
- **DebuggerFrontend** - Story debugger

## Quick Usage

The `divine` command is now available in your terminal:

```bash
divine --help
```

### Common Commands

**Extract a PAK file:**
```bash
divine -g bg3 -s "YourMod.pak" -d "extracted/" -a extract-package
```

**Create a PAK file:**
```bash
divine -g bg3 -s "ModFolder/" -d "YourMod.pak" -a create-package
```

**Convert LSX to LSF:**
```bash
divine -s "input.lsx" -d "output.lsf" -a convert-resource
```

**Convert LSF to LSX:**
```bash
divine -s "input.lsf" -d "output.lsx" -a convert-resource
```

**Convert GR2 to DAE:**
```bash
divine -s "model.gr2" -d "model.dae" -a convert-model
```

## Location

- LSLib installation: `/usr/local/lslib/Packed/`
- Divine command wrapper: `/usr/local/bin/divine`

## Game Options

Use `-g` or `--game` flag with:
- `bg3` - Baldur's Gate 3
- `dos2` - Divinity: Original Sin 2
- `dos2de` - Divinity: Original Sin 2 Definitive Edition

## Compression Methods

Use `-c` flag with:
- `zlib`
- `lz4`
- `lz4hc`
- `none`

For more info: https://github.com/Norbyte/lslib
