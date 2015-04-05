# make  to compile without debug info
# make DEBUG=1 to compile with debug info
ifdef EXPLOIT
TARGET = H.BIN
else
TARGET = H.PRX
endif
TARGET += HBL.PRX

all: $(TARGET)

CC = psp-gcc
AS = psp-as
LD = psp-ld
FIXUP = psp-fixup-imports

PSPSDK = $(shell psp-config --pspsdk-path)

PRXEXPORTS = $(PSPSDK)/lib/prxexports.o
PRX_LDSCRIPT = -T$(PSPSDK)/lib/linkfile.prx

INCDIR = -I$(PSPSDK)/include -Iinclude -I.
LIBDIR = -L$(PSPSDK)/lib

CFLAGS = $(INCDIR) -G1 -Os -Wall -Werror -mno-abicalls -fomit-frame-pointer -fno-pic -fno-zero-initialized-in-bss
ASFLAGS = $(INCDIR)
LDFLAGS = -O1 -G0

ifdef NID_DEBUG
DEBUG = 1
CFLAGS += -DNID_DEBUG
endif
ifdef DEBUG
CFLAGS += -DDEBUG
endif

OBJS_COMMON = \
	common/stubs/syscall.o common/stubs/tables.o \
	common/utils/cache.o common/utils/fnt.o common/utils/scr.o common/utils/string.o \
	common/memory.o common/prx.o common/utils.o
ifdef DEBUG
OBJS_COMMON += common/debug.o
endif

OBJS_LOADER = loader/loader.o loader/bruteforce.o loader/freemem.o loader/runtime.o
ifdef EXPLOIT
OBJS_LOADER += loader/start.o
endif

OBJS_HBL = hbl/modmgr/elf.o hbl/modmgr/modmgr.o \
	hbl/stubs/hook.o hbl/stubs/md5.o hbl/stubs/resolve.o \
	hbl/eloader.o hbl/settings.o

ifdef EXPLOIT
LOADER_LDSCRIPT = -Tloader.ld
else
LOADER_LDSCRIPT = -Tlauncher.ld $(PRX_LDSCRIPT)
endif

LIBS = -lpspaudio -lpspctrl -lpspdisplay -lpspge -lpsprtc -lpsputility

IMPORTS = common/imports/imports.a

EBOOT.PBP: PARAM.SFO assets/ICON0.PNG assets/PIC1.PNG H.PRX
	pack-pbp EBOOT.PBP PARAM.SFO assets/ICON0.PNG NULL \
		NULL assets/PIC1.PNG NULL H.PRX NULL

PARAM.SFO:
	mksfo 'Half Byte Loader' $@

H.BIN: H.elf
	psp-objcopy -S -O binary -R .sceStub.text $< $@

H.elf: $(PRXEXPORTS) $(OBJS_COMMON) $(OBJS_LOADER) $(IMPORTS)
	$(LD) -q $(LDFLAGS) $(LOADER_LDSCRIPT) $(LIBDIR) $^ $(LIBS) -o $@
	$(FIXUP) $@

$(OBJS_LOADER): config.h

HBL.elf: $(PRXEXPORTS) $(OBJS_COMMON) $(OBJS_HBL) $(IMPORTS)
	$(LD) $(LDFLAGS) -q $(PRX_LDSCRIPT) $(LIBDIR) $^ $(LIBS) -o $@
	$(FIXUP) $@

$(OBJS_HBL): config.h

%.PRX: %.elf
	psp-prxgen $< $@

$(OBJS_COMMON): config.h

config.h: config.txt
	-@echo "//config.h is automatically generated by the Makefile!!!" > $@
	-@echo "#ifndef SVNVERSION" >> $@
	-@echo "#define SVNVERSION \"$(shell svnversion -n)\"" >> $@
	-SubWCRev . $< $@
ifdef EXPLOIT
	-@echo "#include <exploits/$(EXPLOIT).h>" >> $@
else
	-@echo "#define LAUNCHER" >> $@
	-@echo "#define HBL_ROOT \"ms0:/HBL\"" >> $@
endif
	-@echo "#endif" >> $@

$(IMPORTS):
	make -C common/imports

clean:
	rm -f config.h $(OBJS_COMMON) $(OBJS_LOADER) $(OBJS_HBL) H.elf HBL.elf H.BIN HBL.PRX H.PRX PARAM.SFO EBOOT.PBP
	make -C common/imports clean
