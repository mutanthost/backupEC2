
Issues fixed in ORAchk  VERSION: 18.4.0_20181129
----------------------------------------------------
Bug 27648594 - orachk/exachk leaves directory behind on storage servers
Bug 28478066 - exachk -d start failed on 18.3.0_20180808 when setting rat_output to nfs dir
Bug 28666702 - ol7: verify basic logical volume(lvm) fails on dbsys
Bug 28672417 - er:ol7: modify ...exachkcfg autostart... to only execute below 19.1
Bug 28722527 - verify permission ... qopiprep.bat logic needs revision
Bug 28776457 - ol7: ex47,ex46,ex27 skipped with "file not found"
Bug 28808826 - jsondecodeerror with varying characters reported
Bug 28906492 - mixed hardware x5/x6 - ex37,ex46 "file not found" on x6 storage servers
Bug 28457336 - rac lnx-191-tfa:orachk start daemon hit unexpected error
Bug 28457782 - rac lnx-191-tfa:start orachk client run with the -fileattr option failed
Bug 28562525 - lnx-191-tfa-chk: ordssetup failed because setup_ords.sh lacking x bit
Bug 28611245 - framework add autonomous heath section to orachk/exachk reports
Bug 28678778 - rac tfa:orachk autorun reports are not getting archived as per retention policy
Bug 28792839 - rac solsp-191-orachk: cmd "orachk -initdebugsetup" hungs and no return
Bug 28793142 - rac solsp-191-orachk: orachk reports fail error for "cluster_interconnects" on fresh installed gi
Bug 28797626 - rac solsp-191-orachk: cmd "orachk -profile ovn" wrong lists rdbms not up
Bug 28823346 - lnx-19.1-tfa:pdbnames in orachk command should be case-insensitive
Bug 28829155 - rac aix-184ru: orachk can't run if there are not enough space in home dir
Bug 28888873 - lnx-19.1-rooh:opatch files were generated in rooh during orachk
Bug 28920813 - lnx64-183-cmt: vlan env 'orachk' didn't work:unexpected error in orachk.py
Bug 28871836 - lnx64-183-cmt: orachk -debug fail, hit error in orachk.py: nonetype: none
Bug 22248009 - inconsistent calculations for free memory


Issues fixed in previous ORAchk releases
----------------------------------------
For a full list of ORAchk version history see https://support.oracle.com/epmos/main/downloadattachmentprocessor?attachid=1268927.1:VERSION_HISTORY.