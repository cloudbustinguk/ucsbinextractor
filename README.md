# ucsbinextractor
Extract Cisco UCS Fabric Interconnect firmware blobs

This is an old script I wrote and submitted to Cisco's community.

It extracts the respective system/kickstart images from the blob. This is handy when you want to set up a TFTP server or just put the individual images online, for quick access during a failed upgrade, etc.

More info from the original post
--------------------------------


Please find attached a basic script to extract the kickstart, system and ucsm firmware from the ucs infra bundle (and others..).  I am not sure as to the exact legality of this, so admin, if you object to this material, feel free to remove it.  This is hardly ground-breaking stuff though, and no encryption is used.  Maybe there's already a well-known way to extract this - let me know if so!

*Background*

The background here is - Cisco bundle the relevant firmware objects in a large blob.  This is not helpful when you need to boot off of an alternate kickstart (for example, during a failed FI upgrade, from tftp) and/or if your system image is corrupt, and you want to copy scp: bootflash:, etc..... during such failed upgrades, we've had to rely on TAC providing them to us, which is not entirely uncomfortable, but does take a bit of time.

If you're downloading firmware for a Nexus device, you conveniently have access to the individual kickstart/system from the outset.

*Cisco's blob format*

Cisco's ".bin" files are headed by a small header, which describes a few things about the bin package, such as the size of the bundled package, the type of hardware platform its for, etc..  Here is some typical output from the 'show' operation of a certain UCS system command, which is available when accessing the system via the debug plugin... however, I won't mention any names   (Incidentally, this command and a helper wrapper script are what perform the exact thing my script does... but of course they do it better, and provide more functionality.)

**********************************************

HEADER CONTENTS

**********************************************

Header version: 1.0

Len: 800 byte

Image length:488933830 byte

Magic number: 21326

Platform type: 7

Verification type: 1

Software family: 2

Image type: 11

Debug attribute: 2

Hardware type: 0

Compression type: 2

Run time location: 1

Packaged by: 0

Memsize: 256

Timestamp: 1482316264

Version string: 3.1(2e)B

Interim version string: 3.1(2e)B

Image full name: ucs-k9-bundle-b-series.3.1.2e.B.bin

Features:

Build ID: S0

**********************************************

Cisco NX-OS(tm) ucs, Software (ucs-k9-bundle-b-series), Version 3.1(2e)B, RELEASE SOFTWARE Copyright (c) 2002-2013 by Cisco Systems, Inc.

-------------------------------

So, Cisco bin files begin with this header, and straight after consist of (usually) an inline tarred-gzip archive.  Depending on the bin file, there may be one or more archvies, as well as a NetBoot Linux image (in the case of kickstart) which is loopback-mountable, and cpio archives (in the case of the IOM/fex/chassis image).

I've only so far implemented basic tar/gzip extraction of the first archive, which is what we actually need - the rest can be done via xxd and searching for the magic numbers of certain archives + dd'ing the image out... and is left as an exercise for the curious... but the script can also be applied to most sub-bin files which arise from the extraction of the main bin file (infra bundle, then system, then plugins, etc...), as most all contain the same cisco header + tgz format.

*Extraction*

Trivial use of the script:

./extractbins.sh: [file.bin] [directory_to_extract_to]

Actual use:

./extractbins.sh ucs-6300-k9-bundle-infra.3.1.2e.A.bin extracted

cisco image extractor 1.1 - dsw(c),2017

[.] cisco image of 756 bytes found in ucs-6300-k9-bundle-infra.3.1.2e.A.bin

[.] seeking past header length 756....

[.] wrote header-less image ucs-6300-k9-bundle-infra.3.1.2e.A.bin.nohdr

[.] gzip found; decompressing..

[.] tar found; untarring..

./

./isan/

./isan/etc/

./isan/etc/climib/

./isan/etc/imghdr.bin

./isan/plugin_img/

./isan/plugin_img/ucs-6300-k9-system.5.0.3.N2.3.12e.bin

./isan/plugin_img/ucs-manager-k9.3.1.2e.bin

./isan/plugin_img/ucs-2300-6300.3.1.2e.bin

./isan/plugin_img/ucs-6300-k9-kickstart.5.0.3.N2.3.12e.bin

./isan/plugin_img/ucs-2200-6300.3.1.2e.bin

[.] cleaning up..

[.] done

Much can be improved and added, but the basic functionality is there.  Bugs: almost certainly.  Please heed the disclaimer in the script.

Cheers

dan
