import glob
import os

TILE_SIZE = 16

DATA = {
    # "CURSORS": [
    #     "graphics/ui/cursors/upper_left_arrow.png",
    #     "graphics/ui/cursors/magnifying_glass.png",
    #     "graphics/ui/cursors/red_crosshair.png",
    # ],
    "HUMAN_PANEL": [
        "graphics/tilesets/forest/portrait_icons.png",
        "graphics/ui/gold_icon_1.png",
        "graphics/ui/lumber_icon_1.png",
        "graphics/ui/percent_complete.png",
        "graphics/ui/human/icon_border.png",
        "graphics/ui/human/icon_selection_boxes.png",
        "graphics/ui/human/panel_2.png",
    ],
    "ORC_PANEL": [
        "graphics/tilesets/forest/portrait_icons.png",
        "graphics/ui/gold_icon_1.png",
        "graphics/ui/lumber_icon_1.png",
        "graphics/ui/percent_complete.png",
        "graphics/ui/orc/icon_border.png",
        "graphics/ui/orc/icon_selection_boxes.png",
        "graphics/ui/orc/panel_2.png",
    ],
    "FOREST_TILESET": [
        "graphics/tilesets/forest/terrain.png",
        "graphics/human/units/*.png",
        "graphics/neutral/units/*.png",
        "graphics/orc/units/*.png",
        "graphics/missiles/*.png",
        "graphics/tilesets/forest/human/buildings/*.png",
        "graphics/tilesets/forest/orc/buildings/*.png",
        "graphics/tilesets/forest/neutral/buildings/*.png",
    ],
    "SWAMP_TILESET": [
        "graphics/tilesets/swamp/terrain.png",
        "graphics/human/units/*.png",
        "graphics/neutral/units/*.png",
        "graphics/orc/units/*.png",
        "graphics/missiles/*.png",
        "graphics/tilesets/swamp/human/buildings/*.png",
        "graphics/tilesets/swamp/orc/buildings/*.png",
        "graphics/tilesets/swamp/neutral/buildings/*.png",
    ],
    "DUNGEON_TILESET": [
        "graphics/tilesets/dungeon/terrain.png",
        "graphics/human/units/*.png",
        "graphics/neutral/units/*.png",
        "graphics/orc/units/*.png",
        "graphics/missiles/*.png",
        "graphics/tilesets/dungeon/neutral/buildings/*.png",
    ],
}

def system(s):
    os.system(s)

def main(data, out, bindir):
    rgb2amiga = os.path.join(bindir, 'bin', 'Rgb2Amiga')
    bitmap_conv = os.path.join(bindir, 'bin', 'bitmap_conv')
    tileset_conv = os.path.join(bindir, 'bin', 'tileset_conv')
    palette_conv = os.path.join(bindir, 'bin', 'palette_conv')

    for name,set in DATA.items():
        inputfiles = []
        pngfiles = []
        bmfiles = []
        for pattern in set:
            for i in glob.glob(os.path.join(data, pattern)):
                output = i.replace(data, out)
                inputfiles.append(i)
                pngfiles.append(output)
                os.makedirs(os.path.dirname(output), exist_ok=True)
                bmfiles.append(output.replace(".png", ".bm"))

        inargs = " -i ".join(inputfiles)
        outargs = " -o ".join(pngfiles)
        system(f"{rgb2amiga} -f png-gpl -s ! -i {inargs} -o {outargs}")
        palette = os.path.join(out, f"{name.lower()}.plt")
        system(f"{palette_conv} {pngfiles[0]}.gpl {palette}")
        for bmfile,pngfile in zip(bmfiles, pngfiles):
            # TODO: mask color is #BBB (i.e., 187 187 187)
            system(f"{bitmap_conv} {palette} {pngfile} -o {bmfile}")
        if name.endswith("_TILESET"):
            system(f"{tileset_conv} {pngfiles[0]}.png {TILE_SIZE} {bmfiles[0]} -plt {palette}")


if __name__ == "__main__":
    import sys
    from argparse import ArgumentParser
    parser = ArgumentParser(sys.argv[0])
    parser.add_argument('--data', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--prefix', required=True)
    parsed_args = parser.parse_args(sys.argv[1:])
    main(parsed_args.data, parsed_args.output, parsed_args.prefix)
