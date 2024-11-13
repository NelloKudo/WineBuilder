# Makefile to bundle fonts to Wine taken from Proton-GE and proton-cachyos,
# read more at: https://github.com/CachyOS/proton-cachyos/blob/cachyos_9.0_20241031/Makefile.in

# Enable secondary expansions, needed for font compilation rules
.SECONDEXPANSION:

SRCDIR := $(shell pwd)
DST_DIR := $(shell echo $$WINE_FONTS_DESTDIR)

.PHONY: fonts

FONTS := $(SRCDIR)/fonts
FONTS_OBJ := ./obj-fonts
ALT_FONTS_OBJ := $(FONTS_OBJ)/alt

FONTFORGE = fontforge -quiet
FONTSCRIPT = $(FONTS)/scripts/generatefont.pe
MERGEFONTSSCRIPT = $(FONTS)/scripts/mergefonts.pe

LIBERATION_SRCDIR = $(FONTS)/liberation-fonts/src
SOURCE_HAN_SANS_SRCDIR = $(FONTS)/source-han-sans
UME_DIR = $(FONTS)/ume

msyh.ttf_CIDFONT = $(SOURCE_HAN_SANS_SRCDIR)/cidfont.ps.OTC.SC
msyh.ttf_FEATURES = $(SOURCE_HAN_SANS_SRCDIR)/features.OTC.SC
msyh.ttf_SEQUENCES = $(SOURCE_HAN_SANS_SRCDIR)/SourceHanSans_CN_sequences.txt
msyh.ttf_UNISOURCE = $(SOURCE_HAN_SANS_SRCDIR)/UniSourceHanSansCN-UTF32-H
msyh.ttf_MENUNAMEDB = $(FONTS)/patches/YaHei-FontMenuNameDB
msyh.ttf = $(FONTS_OBJ)/source-han/msyh.ttf

simsun.ttf_CIDFONT = $(SOURCE_HAN_SANS_SRCDIR)/cidfont.ps.OTC.SC
simsun.ttf_FEATURES = $(SOURCE_HAN_SANS_SRCDIR)/features.OTC.SC
simsun.ttf_SEQUENCES = $(SOURCE_HAN_SANS_SRCDIR)/SourceHanSans_CN_sequences.txt
simsun.ttf_UNISOURCE = $(SOURCE_HAN_SANS_SRCDIR)/UniSourceHanSansCN-UTF32-H
simsun.ttf_MENUNAMEDB = $(FONTS)/patches/SimSun-FontMenuNameDB
simsun.ttf = $(FONTS_OBJ)/source-han/simsun.ttf

nsimsun.ttf_CIDFONT = $(SOURCE_HAN_SANS_SRCDIR)/cidfont.ps.OTC.SC
nsimsun.ttf_FEATURES = $(SOURCE_HAN_SANS_SRCDIR)/features.OTC.SC
nsimsun.ttf_SEQUENCES = $(SOURCE_HAN_SANS_SRCDIR)/SourceHanSans_CN_sequences.txt
nsimsun.ttf_UNISOURCE = $(SOURCE_HAN_SANS_SRCDIR)/UniSourceHanSansCN-UTF32-H
nsimsun.ttf_MENUNAMEDB = $(FONTS)/patches/NSimSun-FontMenuNameDB
nsimsun.ttf = $(FONTS_OBJ)/source-han/nsimsun.ttf

msgothic.ttf_FONT = $(UME_DIR)/ume-tgo4.ttf
msgothic.ttf_NAMETABLE_PATCH = $(FONTS)/patches/UmeGothic-nametable.patch
msgothic.ttf = $(FONTS_OBJ)/ume-gothic/msgothic.ttf

mspgothic.ttf_FONT = $(UME_DIR)/ume-pgo4.ttf
mspgothic.ttf_NAMETABLE_PATCH = $(FONTS)/patches/UmePGothic-nametable.patch
mspgothic.ttf = $(FONTS_OBJ)/ume-gothic/mspgothic.ttf

msuigothic.ttf_FONT = $(UME_DIR)/ume-ugo4.ttf
msuigothic.ttf_NAMETABLE_PATCH = $(FONTS)/patches/UmeUIGothic-nametable.patch
msuigothic.ttf = $(FONTS_OBJ)/ume-gothic/msuigothic.ttf

malgun.ttf_CIDFONT = $(SOURCE_HAN_SANS_SRCDIR)/cidfont.ps.OTC.K
malgun.ttf_FEATURES = $(SOURCE_HAN_SANS_SRCDIR)/features.OTC.K
malgun.ttf_SEQUENCES = $(SOURCE_HAN_SANS_SRCDIR)/SourceHanSans_KR_sequences.txt
malgun.ttf_UNISOURCE = $(SOURCE_HAN_SANS_SRCDIR)/UniSourceHanSansKR-UTF32-H
malgun.ttf_MENUNAMEDB = $(FONTS)/patches/Malgun-FontMenuNameDB
malgun.ttf = $(FONTS_OBJ)/source-han/malgun.ttf

simsun.ttc = $(FONTS_OBJ)/source-han/simsun.ttc
msgothic.ttc = $(FONTS_OBJ)/ume-gothic/msgothic.ttc

noto_sans.ttf = $(FONTS)/noto/NotoSans-Regular.ttf
noto_sans_arabic.ttf = $(FONTS)/noto/NotoSansArabic-Regular.ttf
noto_sans_armenian.ttf = $(FONTS)/noto/NotoSansArmenian-Regular.ttf
noto_sans_bengali.ttf = $(FONTS)/noto/NotoSansBengali-Regular.ttf
noto_sans_bengaliui.ttf = $(FONTS)/noto/NotoSansBengaliUI-Regular.ttf
noto_sans_chakma.ttf = $(FONTS)/noto/NotoSansChakma-Regular.ttf
noto_sans_coptic.ttf = $(FONTS)/noto/NotoSansCoptic-Regular.ttf
noto_sans_devanagariui.ttf = $(FONTS)/noto/NotoSansDevanagariUI-Regular.ttf
noto_sans_georgian.ttf = $(FONTS)/noto/NotoSansGeorgian-Regular.ttf
noto_sans_gujarati.ttf = $(FONTS)/noto/NotoSansGujarati-Regular.ttf
noto_sans_gujaratiui.ttf = $(FONTS)/noto/NotoSansGujaratiUI-Regular.ttf
noto_sans_gurmukhiui.ttf = $(FONTS)/noto/NotoSansGurmukhiUI-Regular.ttf
noto_sans_hebrew.ttf = $(FONTS)/noto/NotoSansHebrew-Regular.ttf
noto_sans_kannadaui.ttf = $(FONTS)/noto/NotoSansKannadaUI-Regular.ttf
noto_sans_khmer.ttf = $(FONTS)/noto/NotoSansKhmer-Regular.ttf
noto_sans_malayalamui.ttf = $(FONTS)/noto/NotoSansMalayalamUI-Regular.ttf
noto_sans_math.ttf = $(FONTS)/noto/NotoSansMath-Regular.ttf
noto_sans_meeteimayek.ttf = $(FONTS)/noto/NotoSansMeeteiMayek-Regular.ttf
noto_sans_mono.ttf = $(FONTS)/noto/NotoSansMono-Regular.ttf
noto_sans_olchiki.ttf = $(FONTS)/noto/NotoSansOlChiki-Regular.ttf
noto_sans_oriyaui.ttf = $(FONTS)/noto/NotoSansOriyaUI-Regular.ttf
noto_sans_sinhalaui.ttf = $(FONTS)/noto/NotoSansSinhalaUI-Regular.ttf
noto_sans_sorasompeng.ttf = $(FONTS)/noto/NotoSansSoraSompeng-Regular.ttf
noto_sans_symbols.ttf = $(FONTS)/noto/NotoSansSymbols-Regular.ttf
noto_sans_symbols2.ttf = $(FONTS)/noto/NotoSansSymbols2-Regular.ttf
noto_sans_tamil.ttf = $(FONTS)/noto/NotoSansTamil-Regular.ttf
noto_sans_tamilui.ttf = $(FONTS)/noto/NotoSansTamilUI-Regular.ttf
noto_sans_teluguui.ttf = $(FONTS)/noto/NotoSansTeluguUI-Regular.ttf
noto_sans_thaana.ttf = $(FONTS)/noto/NotoSansThaana-Regular.ttf
noto_sans_thai.ttf = $(FONTS)/noto/NotoSansThai-Regular.ttf
# Unfortunately Tibetan only exists as Serif
noto_serif_tibetan.ttf = $(FONTS)/noto/NotoSerifTibetan-Regular.ttf

micross.ttf = $(FONTS_OBJ)/micross.ttf
nirmala.ttf = $(FONTS_OBJ)/nirmala.ttf
alt_arial.ttf = $(ALT_FONTS_OBJ)/arial.ttf

#The use of "Arial" here is for compatibility with programs that require that exact string. This font is not Arial.
arial_NAMES := "Arial" "Arial" "Arial"
arial_ORIG := LiberationSans-Regular
#The use of "Arial" here is for compatibility with programs that require that exact string. This font is not Arial.
arialbd_NAMES := "Arial-Bold" "Arial" "Arial Bold"
arialbd_ORIG := LiberationSans-Bold
#The use of "Times New Roman" here is for compatibility with programs that require that exact string. This font is not Times New Roman.
times_NAMES := "TimesNewRoman" "Times New Roman" "Times New Roman"
times_ORIG := LiberationSerif-Regular
#The use of "Georgia" here is for compatibility with programs that require that exact string. This font is not Georgia.
georgia_NAMES := "Georgia" "Georgia" "Georgia"
georgia_ORIG := LiberationSerif-Regular
#The use of "Courier New" here is for compatibility with programs that require that exact string. This font is not Courier New.
cour_NAMES := "CourierNew" "Courier New" "Courier New"
cour_PATCH := $(FONTS)/patches/LiberationMono-Regular.patch
cour_ORIG := LiberationMono-Regular
#The use of "Courier New" here is for compatibility with programs that require that exact string. This font is not Courier New.
courbd_NAMES := "CourierNewPS-BoldMT" "Courier New" "Courier New Bold"
courbd_ORIG := LiberationMono-Bold

$(FONTS_OBJ):
	mkdir -p $@

$(ALT_FONTS_OBJ):
	mkdir -p $@

$(FONTS_OBJ)/%.ttf: $(FONTS_OBJ)/$$($$(*)_ORIG).sfd $(FONTSCRIPT) | $(FONTS_OBJ)
	$(FONTFORGE) -script $(FONTSCRIPT) $< $($(*)_NAMES) $@

$(FONTS_OBJ)/%.sfd: $(LIBERATION_SRCDIR)/%.sfd | $(FONTS_OBJ)
	patch $< -o $@ $(firstword $($(*)_PATCH) /dev/null)

fonts: $(FONTS_OBJ)/arial.ttf
fonts: $(FONTS_OBJ)/arialbd.ttf
fonts: $(FONTS_OBJ)/georgia.ttf
fonts: $(FONTS_OBJ)/times.ttf
fonts: $(FONTS_OBJ)/cour.ttf
fonts: $(FONTS_OBJ)/courbd.ttf

#The use of "YaHei" for compatibility with programs that require that exact string. This font is not Microsoft YaHei.
$(FONTS_OBJ)/source-han/%.ttf: $$(%.ttf_CIDFONT) $$(%.ttf_FEATURES) $$(%.ttf_SEQUENCES) $$(%.ttf_UNISOURCE) $$(%.ttf_MENUNAMEDB)
	mkdir -p $(FONTS_OBJ)/source-han
	# Do not immediately create the target file, so that make is interrupted
	# it will restart again
	makeotfexe -f $($(notdir $@)_CIDFONT) -omitMacNames -ff $($(notdir $@)_FEATURES) \
		-lic ADOBE -mf $($(notdir $@)_MENUNAMEDB) -r -nS -cs 25 -ch $($(notdir $@)_UNISOURCE) \
		-ci $($(notdir $@)_SEQUENCES) -o $@.tmp
	tx -cff +S -no_futile $($(notdir $@)_CIDFONT) $@.cff
	# sftnedit uses a hardcoded temporary file in the local directory, so we have
	# to run it in a dedicated temporary directory to prevent concurrent instances
	# to step onto each other's feet
	(TEMP_DIR=`mktemp -d` && cd $$TEMP_DIR && sfntedit -a CFF=$(abspath $($(notdir $@)).cff) $(abspath $@.tmp) && rm -fr $$TEMP_DIR)
	mv $@.tmp $@

$(FONTS_OBJ)/ume-gothic/%.ttf: $$(%.ttf_FONT) $$(%.ttf_NAMETABLE_PATCH)
	mkdir -p $(FONTS_OBJ)/ume-gothic
	ttx -o $(FONTS_OBJ)/ume-gothic/$(notdir $(basename $($(notdir $@)_NAMETABLE_PATCH))).ttx -t name $($(notdir $@)_FONT)
	patch $(FONTS_OBJ)/ume-gothic/$(notdir $(basename $($(notdir $@)_NAMETABLE_PATCH))).ttx $($(notdir $@)_NAMETABLE_PATCH)
	ttx -o $@ -m $($(notdir $@)_FONT) $(FONTS_OBJ)/ume-gothic/$(notdir $(basename $($(notdir $@)_NAMETABLE_PATCH))).ttx

$(simsun.ttc): $(simsun.ttf) $(nsimsun.ttf)
	otf2otc -o $@.tmp $^
	otf2ttf -o $@ $@.tmp
	rm $@.tmp

$(msgothic.ttc): $(msgothic.ttf) $(mspgothic.ttf) $(msuigothic.ttf)
	otf2otc -o $@ $^

$(micross.ttf): $(FONTS)/scripts/merge.py $(noto_sans.ttf) $(noto_sans_arabic.ttf) $(noto_sans_armenian.ttf) $(noto_sans_bengali.ttf) $(noto_sans_coptic.ttf) \
		$(noto_sans_georgian.ttf) $(noto_sans_gujarati.ttf) $(noto_sans_hebrew.ttf) $(noto_sans_khmer.ttf) $(noto_sans_tamil.ttf) \
		$(noto_sans_thaana.ttf) $(noto_sans_thai.ttf) $(noto_sans_math.ttf) $(noto_sans_symbols.ttf) $(noto_sans_mono.ttf)
	$(FONTS)/scripts/merge.py $(noto_sans.ttf) $(noto_sans_arabic.ttf) $(noto_sans_armenian.ttf) $(noto_sans_bengali.ttf) \
		$(noto_sans_coptic.ttf) $(noto_sans_georgian.ttf) $(noto_sans_gujarati.ttf) $(noto_sans_hebrew.ttf) $(noto_sans_khmer.ttf) \
		$(noto_sans_tamil.ttf) $(noto_sans_thaana.ttf) $(noto_sans_thai.ttf) $(noto_sans_math.ttf) $(noto_sans_symbols.ttf) $(noto_sans_mono.ttf) \
		"MicrosoftSansSerif" "Microsoft Sans Serif" "Regular" $(FONTS)/ranges/micross $(micross.ttf)

$(nirmala.ttf): $(FONTS)/scripts/merge.py $(noto_sans.ttf) $(noto_sans_chakma.ttf) $(noto_sans_bengaliui.ttf) $(noto_sans_devanagariui.ttf) $(noto_sans_gujaratiui.ttf) $(noto_sans_gurmukhiui.ttf) \
		$(noto_sans_kannadaui.ttf) $(noto_sans_malayalamui.ttf) $(noto_sans_meeteimayek.ttf) $(noto_sans_olchiki.ttf) $(noto_sans_oriyaui.ttf) \
		$(noto_sans_sinhalaui.ttf) $(noto_sans_sorasompeng.ttf) $(noto_sans_tamilui.ttf) $(noto_sans_teluguui.ttf) $(noto_serif_tibetan.ttf) $(noto_sans_math.ttf) \
		$(noto_sans_symbols2.ttf)
	$(FONTS)/scripts/merge.py $(noto_sans.ttf) $(noto_sans_chakma.ttf) $(noto_sans_bengaliui.ttf) $(noto_sans_devanagariui.ttf) $(noto_sans_gujaratiui.ttf) \
		$(noto_sans_gurmukhiui.ttf) $(noto_sans_kannadaui.ttf) $(noto_sans_malayalamui.ttf) $(noto_sans_meeteimayek.ttf) $(noto_sans_olchiki.ttf) \
		$(noto_sans_oriyaui.ttf) $(noto_sans_sinhalaui.ttf) $(noto_sans_sorasompeng.ttf) $(noto_sans_tamilui.ttf) $(noto_sans_teluguui.ttf) \
		$(noto_serif_tibetan.ttf) $(noto_sans_math.ttf) $(noto_sans_symbols2.ttf) "NirmalaUI" "Nirmala UI" "Regular" $(FONTS)/ranges/nirmala $(nirmala.ttf)

$(alt_arial.ttf): $(FONTS)/scripts/merge.py $(noto_sans.ttf) $(noto_sans_arabic.ttf) $(noto_sans_hebrew.ttf) $(noto_sans_armenian.ttf) $(noto_sans_coptic.ttf) \
		$(noto_sans_math.ttf) $(noto_sans_symbols.ttf) $(noto_sans_symbols2.ttf) $(noto_sans_mono.ttf) | $(ALT_FONTS_OBJ)
	$(FONTS)/scripts/merge.py $(noto_sans.ttf) $(noto_sans_arabic.ttf) $(noto_sans_hebrew.ttf) $(noto_sans_armenian.ttf) $(noto_sans_coptic.ttf) \
		$(noto_sans_math.ttf) $(noto_sans_symbols.ttf) $(noto_sans_symbols2.ttf) $(noto_sans_mono.ttf) "Arial" "Arial" "Regular" $(FONTS)/ranges/arial $(alt_arial.ttf)

fonts: $(msyh.ttf)
fonts: $(simsun.ttc)
fonts: $(msgothic.ttc)
fonts: $(malgun.ttf)
fonts: $(micross.ttf)
fonts: $(nirmala.ttf)
fonts: $(alt_arial.ttf)

DIST_FONTS := $(DST_DIR)
$(DIST_FONTS): fonts
	mkdir -p $@
	cp $(FONTS_OBJ)/*.ttf "$@"
	cp $(FONTS_OBJ)/source-han/msyh.ttf "$@"
	cp $(FONTS_OBJ)/source-han/simsun.ttc "$@"
	cp $(FONTS_OBJ)/ume-gothic/msgothic.ttc "$@"
	cp $(FONTS_OBJ)/source-han/malgun.ttf "$@"
	cp -r $(FONTS_OBJ)/alt "$@"

all-dist: $(DIST_FONTS)
