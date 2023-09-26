                                Inside Elf/OS
                                   V 0.2.7
                                     by
                               Michael H. Riley


Introduction:
-------------
  Elf/OS is a disk operating system for Elf-class computers.  It is written
entirely in 1802 assembly language.  It was designed to use a BIOS that 
abstracts the underlying hardware and is therefore very portable among a
variety of 1802 based systems.  Although Elf/OS was originally written to run
on the Micro/Elf, it has been succesfully used on the Elf II, Super Elf,
Elf 2000 and a number of home built Elf computers.

  Elf/OS provides for control of disk resources and allows programs to use
disk storage without the difficulties in maintining an on-disk filesystem.
Multi-level directories are also supported by Elf/OS.

  This document will describe how Elf/OS works, starting with overviews of 
its major functions and then diving into each of the subroutines that makes
Elf/OS work.


-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
Disk Structure:
---------------
  Before discussing the Elf/OS source it is important to understand what the
disk structure is that Elf/OS expects.  Elf/OS interfaces to the BIOS and 
utilizes disks in LBA (Linear Block Address) mode.  To Elf/OS the storage
device looks like a long string of 512 byte blocks or sectors.  It is up to
the BIOS to use the appropriate LBA mode of the attached physical device or
do head/track/sector conversions.

  The disk is divided into 4 major divisions: System Data Sector, Kernel
Image Block, LAT or Lump Allocation Table, and then the Common Data Area.
There is no fixed area for directories.  Directories, including the master
directory, are handled as files in the common data area.

System Data Sector:
-------------------

  The system data sector occupies sector 0 and contains the Elf/OS boot
loader as well as some disk information that describes the disk filesystem.

  The boot loader is located in the first half or 256 bytes of the system
sector.  Its job is to load the kernel from the Kernel Image Block into 
memory and then transfer control to the kernel

  The second half of the SDS contains the following information (offsets 
are from the beginning of the sector):

    Offset        Meaning
    100h-103h     This entry contains the total number of sectors on the
                  disk device.  The most significant byte of the sector
                  count is in 100h, least significant in 103h.  The Elf/OS
                  kernel does not actually use this entry, it is only used
                  by FSGEN when the filesystem is being crated.
    104h          This entry contains the filesystem type for the disk.  So
                  far all versions of Elf/OS support only filesystem type 1
                  which is Elf/OS 16-bit LAT.
    105h-106h     This entry specifies in which sector the master directory
                  begins.  Normally the first lump of the Common Data Area
                  is the master directory, but this need not be.  As long
                  as the sector number is within the first 64k sectors of
                  the disk the master directory can exist in any lump.
    107h-109h     Reserved.  Not currently used by Elf/OS
    10Ah          This entry specifies how many sectors a lump comprises.
                  Normally Elf/OS uses 8 sectors per lump, or 4kbytes per
                  lump.  All versions prior to 0.2.7 could only use 8
                  sectors per lump.  Starting with 0.2.7 any power of 2 can
                  be used for the lump size.
    10Bh-10Ch     In type 1 filesystems, this entry specifies how many AUs
                  (Allocation Units, which are synonomous with lumps) exist
                  on the disk.  
    10Bh-10Eh     In non type 1 filesystems, this entry specifies how many AUs
                  exist on the disk.
    12Ch-14Ch     This area comprises the directory entry (or DIRENT) for the
                  master directory

Kernel Image Block:
-------------------

  Sectors 1 through 16 comprise the Kernel Image Block.  The Elf/OS kernel
is placed in these sectors by the SYS tool.  The boot loader will load these
16 sectors into memory.

Lump Allocation Table:
----------------------

  The Lump Allocation Table, or LAT starts at sector 17 and uses as many 
sectors as needed in order to map the entire disk.  In a type 1 filesystem
each LAT sector holds 256 LAT entries, each one being 16 bits in size.
The position of an entry in the LAT table determines where on the disk the
sectors that belong to that lump are located.  The first entry in the LAT, or
the first entry in sector 17 specifies physical sectors 0 through 7 (when
using 8 sectors per lump), the second entry in the LAT is for sectors 8 
through 15, and so forth.  Even tho the SDS and KIB are permanently allocated
they still have entries in the LAT table.  The LAT table will use as many 
sectors as needed to fill the lump at the end of the table, in other words it
will always end on a lump boundary.  If the LAT entries map beyond the total
number of AUs on the drive, the nonexistant AUs will be marked with 0FFFFh.

  The entries in the LAT table can be as follows:

    Value     Meaning
    00000h    This specifies an available or unallocated entry.
    0FEFEh    This entry is allocated to a file and contains the EOF for the
              file
    0FFFFh    This entry marks an entry as being either nonexistant (off the
              end of the disk) or non-allocatable.  Non-allocatable AUs are
              the SDS, KIB, and LAT sectors.

  All other entries specify the next lump in the chain of a file.  For example
if an entry contains 0123h, this specifies that the file continues on into
lump number 0123h.  If that was the last lump of the file then lump entry
number 0123h would contain an 0fefeh.

  To convert a lump number to the first sector number of the lump all you
have to do is mulitply the lump number by the number of sectors per lump.
So for example, if the allocation size is 8 sectors per lump and you want the
starting sector for lump 100, you would do 100 * 8, which equals sector 800.
You can also reverse this calculation in order to determine which lump a
sector belongs to, just take the sector number and divide by the allocation 
size, rounding down. so if you wanted to know which lump sector 220 belonged
to, you would do 220 / 8, which equals 27.5, drop the .5 and now you know
that sector 220 belongs to lump 27.

  To find where in the LAT table a particular lump entry is, use the
following calculations (type 1 filesystems):

  LAT_Sector = (Lump / 256) + 17
  LAT_Entry_in_Sector = Lump MOD 256
  Offset_in_sector = LAT_Entry_in_Sector * 2

  To convert a LAT Sector/Entry number into the lump number, use these
calculations (also for type 1 filesystems):

  lump = (LAT_sector - 17) * 256 + Entry_number

  Entry_number is obtained by taking the offset in the sector divided by 2.

Common Data Area:
  After the last lump of the LAT table begins the Common Data area.  It is
in this area that all files and directories are stored.  Normally the first
lump of this area is allocated to the Master Directory.

Directories:
------------

  Directories exist on disk as flat files.  In fact there is nothing special
about directories other than having flag0 set to 1.  Directories can be 
opened and manipulated just like any other file.  If you write to directory
files you must take care that you do not damage the disk structure by 
writing invalid values into directory entries.

Directory Entries or DIRENTs:
-----------------------------

  Each file or directory on the disk is identified by a DIRENT.  The Master
Directory has its DIRENT starting at offset 12Ch of the System Data Sector.
All other files and directories have their DIRENTs in either the Master 
Directory or some other subdirectory.

  The structure of a DIRENT is as follows:

    Offset      Meaning
    00h-03h     This field specifies which lump number is the first AU for
                this file.  This can be converted directly to the first 
                sector number by multiplying by the number of sectors per
                lump.  The most significant byte is in offset 00h and the
                least significant is in offset 03h.  If this DIRENT is not
                allocated then this filed will be all 00.
    04h-05h     This field specifies at which byte in the final lump the 
                end of file is located.  It is important to understand that
                this is the offset in the LAST lump of the file where the
                EOF is located, it is not an offset from the beginning of 
                the file.
    06h         This contains file flags.  So far only bit 0 is defined, all
                others are reserved.  If bit 0 is set then this DIRENT is 
                for a subdirectory.
    07h-08h     This field contains the date that the file was last written
                to.  The date is encoded in this field as follows:
                   Byte 07h   Byte 08h
                   7654 3210  7654 3210
                   |______||____||____|
                     YEAR    MO    DY
                This field will only contain valid values if the machine has
                an RTC installed.
    09h-0Ah     This field contains the time that the file was last written
                to.  The time is encoded in this field as follows:
                   Byte 09h   Byte 0Ah
                   7654 3210  7654 3210
                   |____||______||____|
                     HR    MIN    SEC/2
                Just like the date field, this field will only have valid 
                values if an RTC is present.
    0Bh         Supplementary flags.  None currenty defined.
    0Ch-1Fh     This field contains the filename, zero terminated.

File Descriptors:
-----------------
  All of the Elf/OS API calls that operate on disk files need a file
descriptor or FILDES to operate on.  The FILDES is created when the file
is opened or created and handed back the program that opened the file.
The FILDES is 19 bytes long and holds information necessary for the kernel
to work on the file.  Normally you should not change any of the fields in
an open FILDES, otherwise you could very easily corrupt your filesystem.

  The following fields are part of the FILDES:
    Offset      Meaning
    00h-03h     This field contains the current offset into the file.  This
                field will be updated whenever the file is read or written,
                or if a seek operation is performed.  This field can be 
                read if you want to know the current offset is in the file.
                The most significant byte of the offset is in 00h and the
                least is in offset 03h.  This value should NOT be changed
                by any means other than using o_seek.
    04h-05h     This field specifies the address of where this file's DTA,
                or Data Transfer Area, is located.  The DTA must be 512
                bytes in length and must be provided by your program.  You
                normally set this field prior to opening the file.  while 
                the file is opened, the DTA will always hold the sector
                data where the current offset is pointing.
    06h-07h     This field is the EOF for the file.  This is directly copied
                from the DIRENT when the file is opened.  And just like in
                the DIRENT, this is the EOF offset in the final lump of the 
                sector.
    08h         This sector contains file flags, defined as follows:
                  Bit   Meaning
                    0   Sector has been written to.  This flag will be set
                        whenever this sector gets modified by an o_write
                        call.
                    1   File is read only.  If this bit is set then o_write
                        will produce an error.  This indicates that the 
                        file was requested to be opened as read only.
                    2   This bit is set if the current file pointer is 
                        inside the final lump of the file.  Elf/OS will only
                        check for EOF condition if this bit is set.  This
                        bit should never be changed manualy.
                    3   This bit if set specifies a descriptor that is not
                        in use.
                    4   This bit is set if the file is written to.  When the
                        file is closed, this bit will be checked to see if
                        the date and time for the file need to be changed.
                    5   Reserved
                    6   Reserved
                    7   Reserved
    09h-0Ch     This field contains the physical sector number of which
                sector holds the DIRENT for this file.  This field is filled
                in when the file is opened and should never be modified.
    0Dh-0Eh     This field contains the offset into the directory sector 
                where this files DIRENT is located.  This field is also
                filled in when the file is opend and should never be modified.
    0Fh-12h     This entry contains the sector number that is currently
                loaded into the DTA.  This field will be updated whenever
                Elf/OS changes the sector that is loaded in the DTA.  This
                field should never be modified by the user.
                  

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

Functional Overview:
--------------------
  
  This section will describe on an overview level, what happens in the system
for the various operations.

Cold Boot:
----------
  1. The BIOS loads sector 0 into memory starting at 100h
  2. Control is transferred to the boot routine at 100h.  The boot routine
     will then load sectors 1 through 16 into memory starting at offset 300h
  3. After all the sectors have been loaded, control is transferred to 300h
     which is where Elf/OS's coldboot vector is located.
  4. The coldboot: routine setups R4 and R5 by using the BIOS f_initcall
     routine.
  5. Next the IDE device is reset and the default path is set to /, the 
     root directory.
  6. lmpsize: is then called to set lmpshift for the correct number of
     sectors per lump.
  7. The kernel will next try to execute /INIT.  If /INIT exists and exits
     properly control will then be transferred to welcome:. If /INIT does
     not exist then f_setbd will be executed to get the terminal baud rate.
     Note that if /INIT is found and run, f_setbd will NOT be called by
     the kernel.  This was to allow for /INIT to setup some other terminal
     device and therefore the autobaud would not be needed.  If you are 
     using the default terminal but still need an init routine run, then 
     you would need to add the call to f_setbd inside your init program.
  8. At welcome: the Elf/OS boot message will be displayed and then fall
     through to the warmboot: routine.
  9. warmboot: sets the stack pointer to the correct address and sets
     the stack to R2
 10. Control is then transferred to the main command loop.

Main Command Loop:
------------------
  1. The main comman loop starts at cmdlp: and initial will display the
     system prompt and then wait for a line to be input by the user.
  2. Since Elf/OS contains no inbuilt kernel commands any line typed by
     the user specifies an external program to be run, therefore exec:
     will be called to attempt execution of the specified program.
  3. If exec: returns with DF not set then the program was executed and
     exited normally.  In this case control is transferred back to the 
     beginning of the main command loop.
  4. If the program could not be executed then control is transferred to
     curerr:.  curerr: will call execbin: to see if the program can be
     executed from the /BIN directory.
  5. If the program is found in /BIN it will be executed and then control
     will be transferred back to the beginning of the main command loop.
  6. When the program could not be found in /BIN as well, an error will
     be displayed and then control passes back to the beginning of the
     main command loop.

Program Execution (exec:):
--------------------------
  1. exec: will first look to find where the program name ends and any
     arguments begin.  A terminater will be placed at this point so
     that open: can be called to attempt to open the program to be
     executed.  If open: fails at this point control will be returned to
     the caller with DF set to indicate an error
  2. When the file is opened succesfully the first 6 bytes of it are read.
     These first 6 bytes are the executable header and tell Elf/OS where
     to load the file.  The first 6 bytes of the file are defined as:
       Offset    Meaning
       0-1       This is the address in memory where the program needs to
                 be loaded
       2-3       These 2 bytes specify how many bytes of the file are to
                 be loaded.  Note, it is not necessary to load the entire
                 file into memory and therefore the memory footprint can
                 be smaller than the actual executable file.  This allows
                 for possible overlays or data added at the end of the 
                 executable image.
       4-5       This the execution address for the program.  Control
                 is transferred to this address when the program is
                 successfully loaded.
  3. read: is called to read in the specified number of bytes from the
     executable file.  If an error is reported by read: then control will
     be transferred back to the caller with DF set to indicate an error
     has occurred.
  4. If no read error occurred then control will be transferred to the 
     address specified in the executable header.  This call is made
     using SCAL and if the program maintains the stack can use SRET
     to exit and return back to exec:
  5. If the program returned back with SRET then DF will be cleared to
     indicate that no error occred and control will then be transferred
     back to the caller of exec:

Opening a File (open:):
-----------------------
  1. To open a file for reading/writing open: is called.  The first thing
     open: will do is validate that the filename passed to is is valid.
     If the filename has invalid characters in it or is zero length then
     an error condition DF=1 is set and control is transferred back to
     the caller.
  2. finddir: is called in order to find the directory that holds the 
     specified program.
  3. searchdir: is then called to see if the current (or specified) 
     directory contains the requested file.  If the file does not exist
     then control is transferred to newfile: (step 8.)
  4. The open flags are then checked to see if the truncate has been
     specified.  If it has then the file chain for this file is deleted and
     DIRENT is updated to indicate a zero length file.
  5. The directory containing the file is closed and setupfd: is called
     to setup the FILDES for the opened file.  setupfd: will load the DTA
     with the first sector of the file in addition to setting up the FILDES
     to prepare it for file operations.
  6. The open flags are checked to see if the append option was selected.  
     If it was then the file will be seeked to the end using seekend:
     Since seekend: does not load a physical sector but merely setup the
     FILDES to point to the last sector in the file, loadsec: is called in
     order to load the final sector into the DTA.
  7. Control is transferred back to the caller.
  8. If the file did not exist then the flags will be checked to see if
     file creation is allowed.  If not allowed then control is transferred
     back to the caller with DF set to indicate an error.
  9. freedir: is called in order to find an available slot in the current
     directory.  freedir: will add to the directory file if no free entries
     were found.  so freedir: will always return a valid free DIRENT.
 10. create: is called to create the file.  create: will allocate space
     for the file and then setup the FILDES for file operations.

Closing a File (close:):
------------------------
  1. checkwrt: will be called to see if the sector currently in the DTA
     has been written to.  If so then checkwrt: will write that sector
     back to the disk.
  2. The flags are then checked to see if this file had been written to
     (bit 4 of the FILDES flags).  If not then control is transferred
     back to the user.
  3. The directory sector and offset holding this file's DIRENT will be
     retrieved from the FILDES and that sector will be loaded using
     readsys:
  4. EOF is copied from the FILDES to the DIRENT.
  5. gettmdt: will be called to get the date and time the file was 
     closed.  This is only meaningful if an RTC is present in the
     machine.
  6. writesys: is then called to transfer the directory sector back to
     disk.

Reading a File (read:):
-----------------------
  1. settrx: is called in order to setup the registers for the transfer
     of bytes from the DTA to the users specified buffer.
  2. The bytes read counter is cleared.  
  3. A check is made to see if all the requested bytes have been read, 
     if not then control is trandferred to read1:
  4. Otherwise the bytes read count is moved to the return value and
     control is transferred back to the user with the number of bytes
     read.
  5. read1: will first call checkeof: to see if the file pointer is
     at the end of the file.  If no bytes are left then the bytes
     left to read counter is cleared and control is transferred back
     to readlp: (step 3) which will now be able to exit since there
     will be no more bytes to read
  6. A byte is transferred from the DTA to the users buffer.
  7. incofs: is called to update the file pointer.  incofs: will also check
     if a sector or lump boundary is crossed and load the next sector in
     if a boundary is crossed.  incofs: will set the EOF flag in the FILDES
     if the file pointer is moved into the last lump of the file.
  8. If incofs: indicates that a new sector was loaded then settrx: will 
     be called to resetup the DTA pointers.
  9. Control passes back to readlp: (step 3) to continue reading bytes.

Writing a File (write:):
------------------------
  1. Check the FILDES flags and see if this file was opened readonly.
     If the file is opened readonly then return to the caller.
  2. Call settrx: to setup the DTA transfer registers.
  3. Clear the bytes written counter
  4. Check to see if there are any more bytes to write.  If all the 
     requested bytes have been written then transfer the write count to
     the return register and return to the caller.  Otherwise control is
     transferred to write1:
  5. The FILDES flags are updated to indicate that both the sector and
     the file habe been written to.
  6. Transfer a byte from the users buffer to the DTA.
  7. checkeof: is called to see if the pointer was pointing to the EOF
     of the file.  If not then control is transferred to write2:  If the
     EOF was written then the EOF in the FILDES will be incremented.
     A check will be made if the write to the EOF crossed a lump boundary,
     and if it is then append: will be called to append another lump to
     the file.
  9. write2: incofs: will be called to update the current file pointer.
     Just like in read: if a sector or lump boundary are crossed then
     the next sector for the file will be loaded.  If a newly loaded 
     sector is in the last lump of the file then the EOF flag in the 
     FILDES flags will be set.
 10. If incofs: indicated a new sector was loaded then settrx: will be
     called to resetup the transfer registers.
 11. Control is then transferred back to writelp (step 4)



-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

Elf/OS subroutines in depth:
----------------------------

-----------------------------------------------------------------------------

append:       Append a lump to end of current file

  This function is called whenever a new lump needs to be added on to the
end of a file.

  append: starts by saving RA and then calling freelump: in order to allocate
a lump to append.  If a free lump was available then control is transfered
to append1: otherwise DF will be set to indicate that a lump was not 
available and control falls through to appende:

  appende: restores the original value of RA and then returns to the caller.

  append1: saves additional registers that will be consumed and then calls
startlump: in order to get the first lump number for the file.

  append2: begins a loop where the lump number is checked to see if it is
0FEFEh, the end of file code.  If it is then control is transferred to 
append 4: otherwise the lump value is copied and readlump: is called in 
order to get the next lump in the chain.  Control is transferred back to
append2: again to check for the end of chain code.

  append4: starts by transferring the last lump of the file to RA in
preparation to write the new lump found when freelump: was called earlier.
writelump: is called in order to write the new lump value into the entry
for the original last lump entry.

  The new lump number is then transferred to RA so that a 0FEFEh code can
be written to indicate the new last lump.  writelump: is called in order to
write the end of chain code into the newly appened lump entry.

  getfdflgs: is called to get the flags byte from the FILDES and bit 2 is
cleared to indicate that the sector in the DTA is no longer in the last
lump of the file.
 
  Comsumed registers are then restored to their original values before
control is transferred to appende:

-----------------------------------------------------------------------------

chdir:        Change/view current directory

  This function is the destination of the o_chdir API call.  It is used in
order to set the current working directory or to retrieve what the current
working directory is.

  chdir: starts by examining the first byte of the buffer passed by the
caller.  If the first byte is 00, then get working directory is the 
requested function and control is transferred to viewdir:

  finalsl: is called in order to force a final slash on the end of the
pathname that will be set as the new path. 

  Consumed registers are then saved before calling finddir:.  finddir: will
attempt to open the specified directory path.  This is done in order to
verify if the path passed to this function actually exists within the 
filesystem.

  The return value from finddir: is stored in RE.0 so that consumed
registers can be restored back to their original value.  The the value
in RE.0 is checked to see if finddir: resulted in an error, and if an
error was reported then control is passed th chdirerr:

  Next the path needs to be copied into the system path variable.  First
the first byte of the new pathname is checked to see if it is an absolute
path.  If the path is absolute then control is transferred to chdirlp:

  chdirlp2: will increment RA, which is pointing to the system path variable,
until the end of the current path is found.  Once the end is found then RA
is set to point to the terminator, which is where the new pathname needs to
be appended.  And then control falls through to chdirlp:

  chdirlp: will copy the new pathname pointed to by RF to the system path
variable pointed to by RA.  Once the path has been completely copied, RA
is restored to its original value and control is passed back to the caller.

  viewdir: is the portion of this routine that copies the system path into
the buffer supplied by the caller.  It first saves registers it consumes
and then sets the system path address into RA.  The viewdirlp: then copies
bytes from RA, the system path, to RF, the caller's buffer, until a 
terminator is found.  Once the copy is complete then consumed registers are
restored and control transferred back to the caller.

-----------------------------------------------------------------------------

checkeof:     Check if file is at end

  This function is called to determine if the current file pointer is
pointing at the EOF byte for the file.

  checkeof: starts by saving consumed registers and then builds the mask
needed to check for EOF.  The mask is built by staring with the mask for
a sector, 1h.  The check for eof needs to check values outside of the sector
address range, since a sector holds 512 bytes, we need not mask the bottom
8 bits and the mask needs to start at the first bit of the next address
byte.  The value in lmpshift, shift count that converts sector/lump numbers,
is then used to shift the mask left for each shift needed for the conversion.

  Next RD, the FILDES pointer is move to the flags offset at 8.  The flags
are read and then checked to see if bit 2 is set.  If bit 2 is clear, then
the file pointer is not located in the final lump so control is transferred
to noeof: where DF is cleared to indicate not at end and then control is
transferred back to the caller.

  Next the current offset is masked to get only the values that would be
offsets within the current lump of the file, these are then compared to the
EOF field within the FILDES.  If the offset does not match the EOF value
then control is transferred to noeof: in order to indicate that the
file was not at the end.

  ateof: setsup DF to be set, indicating that the file pointer is pointing
at the final byte of the file.  control then follows through to checkeofe:

  checkeofe: first transfers the result code into DF, then restores the
registers consumed by this routine and then transfers control back to
the caller.

-----------------------------------------------------------------------------

checkwrt:     Check to see if a sector needs to be written

  This routine checks to see if the sector currently in the DTA of the
specified FILDES needs to be written.  A sector only needs to be written
if it has been modified.

  Bit 0 of the FILDES flags field specifies if the current sector has been
written to, so RD is incremented by 8 to point to this field and it is 
retrieved and ANDed with 1 to see if it is set.  If the sector has been
written to then control is transferred to checkwrt1: otherwise the RD is
restored back to the beginning of the FILDES and the routine returns to the
caller.

  At checkwrt1: consumed registers are saved and then RD is moved to point
to the current sector field at offset 15.  RD was already pointing to offset
8 in order to read the flags, so only 7 needs to be added at this point.
The current sector number is then copied into R8:R7 which specifies the
sector number to rawrite:

  After retrieving the current sector number, RD is moved back to the 
beginning of the FILDES and rawwrite: is called to perform the actual
write to disk.

  Afterwards the consumed registers are restored and control is returned
to the caller.

-----------------------------------------------------------------------------

cklstlmp:     Check for last lump and EOF

  This function is called to see if the last loaded sector is in the final
lump of a file.

  After consumed registers are saved, readlump: is called to get the value
of the current lump.  This is checked for 0FEFEh, the end of chain code.
If the lump value was not 0FEFEh then control is transferred to cklstno:

  getfdflgs: is called in order to get the flags for the specified FILDES.
Bit 2 of the flags is set to indicate that the file pointer is in the final
lump of the file.  setfdflgs: is then called to put the flags back into
the correct location in the FILDES.

  Next getfdeof: is called to get the DIRENT's idea of where the EOF of
the file is located.  This value is stored on the stack for later subtraction.
getfgofs: is then called to get the current file pointer.  The read EOF
value in memory is then subtracted from the file offset to determine if
the offset is beyond the EOF byte.  If the file pointer is less than the
EOF byte then control is transferred to cklstdone:

  If the file pointer is beyind the EOF then the file pointer is truncated
to the lump boundary and stored back into the FILDES by calling setfdeof:
The reason for this is if the file pointer is moved beyond the end of the
EOF by a seek, the file can be extended up to the new file pointer postion.
Control is then trasnferred to cklstdone:

  At cklstno: getfdflgs: is called to get the FILDES flags and bit 2 is
cleared to indicate that the file pointer is not in the final lump of the
file and setfdflgs: is called to set the flags back into the FILDES.

  cklstdone: restores all the consumed registers back to their original
values and returns to the caller.

-----------------------------------------------------------------------------

close:        Close a file

  This function is the destination of the o_close API call.  It is used to
close an open FILDES.

  close: first calls checkwrt: to see if the sector currently in the DTA
has been written to.  If it had been altered then checkwrt: will write the
sector back to disk.

  Next RD is incremented by 8 to point to the FILDES flags.  The flags byte
is retrieved and bit 4 is checked to see if this file had been written to.
If the file was written to, then control is transferred to close1: otherwise
control falls through to closeex:, if the file was not written to, then no
special action needs to be taken, control can just be transferred back to
the caller.

  closeex: moves RD back to the beginning of the FILDES and returns.

  If the file had been written to then the DIRENT for this file needs to be
updated.  This starts at close1: where RD is moved forward to the directory
sector field.  Consumed registers will be saved and then the directory
sector bytes will be read into R8:R7 and then readsys: is called to read
the directory sector into the system DTA

  While the directory sector was copied into R8:R7, RD was incremented to
the beginning of the directory offset field so these 2 values are copied 
from the FILDES and placed onto the stack where they can be added into the
system DTA address.  The addition of the system DTA address will lever R9
pointing to physical memory where this files DIRENT exists in the system
DTA.

  Next R9 is moved to the DIRENT EOF field at offset 4 and RD is moved back
to the EOF field at offset 6 in the FILDES.  Once the pointer are set then
the EOF position is copied from the FILDES to the DIRENT

  R9 is then moved to point to the data/time fields in the DIRENT and 
gettmdt: is called in order to attempt to get the current date and time
from the BIOS.  The date and time will be written into the DIRENT and then
writesys: will be called to write the directory sector back to disk.

  Consumed registers will be restored and control is then transferred back
to the caller.

-----------------------------------------------------------------------------

cmdlp:        Main command loop

  This loop is Elf/OS's main command loop.  It is here that Elf/OS queries
the user for a command to execute.

  cmdlp: starts by display the ready prompt to the user by calling d_msg:.

  keybuf is the main buffer that Elf/OS uses to accept a line of text from
the user.  RF will be set with this address and then o_input: is called to
obtain the user's input.

  After the input has been received d_msg: is again used to print a <CR><LF>
pair to the terminal, forcing the cursor to the next line.

  Since Elf/OS has no built-in commands, everything input by the user is
assumed to be an executable program.  Therefore RF is set back to the 
beginning of the keybuffer and exec: to attempt to start the program.

  If exec: returns without error then control is passed back up to cmdlp:
for the next user command.

  When exec: results in an error, namely, the file was not found, then RF
is pointed back to the beginning of keybuf and a call is made to execbin:
which attempts to start a program located in the /BIN directory.  If this
returns without error then control is again traferred back to cmdlp: for
the user's next command.

  When execbin: also results in an error then a file not found error will
be displayed and control is transferred back to cmdlp: for the next command.

-----------------------------------------------------------------------------

coldboot:     Coldboot routine

  coldboot: is the target of the o_coldboot API call.  This is also the
point at which the bootloader transfers control after the kernel is loaded
into memory.

  Since no assumptions can be made at this point it is necessary to set R4
and R5 for use with the SCALL/SRET calling convention.  A temporary stack
is setup at 00FFh and then f_initcall is used to setup R4 and R5 and then
transfer control to start:

  start: first calls f_idereset: in the BIOS to reset the IDE device to a
known state and then sets the working path to the root directory.

  The main stack is then set into R2 and lmpsize: is called to setup lmpshift.

  At this point Elf/OS sets RF to point to a string 'INIT' and calles exec:
to see if /INIT can be executed.  If no error is returned from exec: then
control is bassed to welcome: otherwise f_setbd: is called to setup the
default serial terminal baud rate.  f_setbd: is only executed if the attempt
to exec: /INIT fails.  The reason for this is that for other terminal setups
the autobaud may not be desirable and therefore an /INIT program can be
created to setup the terminal or other i/o devices.  If /INIT is used and
the default serial mode is still desired then it is up to the user's /INIT
program to call f_setbd.

  welcome: will print the 'Starting..." message by calling d_msg: and then
fall through to the warmboot: routine.

-----------------------------------------------------------------------------

create:       Create a new file

  This routine is called in order to create a new file on the filesystem.
It is normally called by open: and mkdir:

  create: starts by saving consumed registers and then setting RB up to
the scratch area, which will represent the DIRENT of the newly created 
file.  

  freelump: is called in order to allocate this file's first lump and it
is written into the new DIRENT.  Following the first lump number the EOF
field of the DIRENT is set to zero, indicating that the file currently 
has no bytes in it.  The create flags are then retrieved from the stack
and stored into the flags field of the DIRENT.

  the loop at create1: sets the file's data/time to all zeros as well as
the supplementary flags byte.

  create2: then copies the filename into the DIRENT.

  Next getsecofs: is called on the FILDES of the enclosing directory in
order to get the current sector loaded into the directory's DTA.  RF is
set to point to the newly created DIRENT and write: is called to write
the 32 bytes of the new DIRENT into the directory file.  close: is then
called in order to close the directory and save the changes in the DTA
back to disk.

  The new FILDES is then retrieved into RD and setfddrsc: and setfddroff:
are called to write the directory sector/offset obtained near the beginning
of create2:, into the file's FILDES.  Then R8:R7 are cleared, indicating
the current file offset is 0, and setfdofs: is called to write the current
file offset to the FILDES.

  Next R8:R7 are set to -1, 0ffffffffh, in order to indicate that the DTA
does not contain a valid sector, and setfdsec: is called to write the
current sector to the FILDES.

  setdflgs: is then called to set the FILDES flags to 4, indicating that
the current file pointer is located in the final lump of the file.  In a
newly created file, there is only 1 lump.  setfdeof: is then called with
an argument of zero to indicate that the EOF for the file is located at
the very beginning of the lump.

  Since a newly created file has only a single lump, the lump assigned to
this file needs to have its entry set to 0FEFEh to indicate the end of 
chain.  RF is set to the end of chain value and writelump: is called to
write the code into the lump's LAT entry.

  Next lumptosec: is called in order to obtain the physical sector that
starts the file and rawread: is then called to load the first sector of the
file into the DTA.

  Consumed registers are then recovered and control returned to the caller.

-----------------------------------------------------------------------------

delchain:     Delete a chain of lumps

  This function is called when a file is deleted or truncated.  The purpose
of this function is to deallocate all of the lumps that were allocated to
the deleted/truncated file.

  delchlp: is the main loop that walks along the chain of lumps.  First it
makes a copy of the current lump number and then calls readlump: to get the
value of the lump following the current lump.

  The next lump value is stored in RB so that the current lump number can
be transferred from RC back to RA.  RF is set to 00 which is the value for
an unallocated lump and writelump: is called to write the 00 to the current
lump entry, thus deallocating it.

  The next lump stored in RB is then moved into RA as the current lump and
checked to see if it is the end of chain code of 0FEFEh.  If the end of the
chain has not been reached then control is passed back to delchlp: to 
continue deallocating lumps.

  Once the entire chain of lumps has been deallocated, the consumed 
registers are restored and control passed back to the caller.

  the loop at create1: zeroes out the date and time for the new file.
-----------------------------------------------------------------------------

delete:       Delete a file

  This function is the destination of the o_delete API call and is used to
delete a file from the filesystem.

  First consumed registers are saved and then finddir: is called to get an
open directory of where the file is located.  searchdir: is then called
in order to find the desired filename within the directory.  If the DIRENT
was found for the file then control is transferred delfile: to continue the
delete process.  Otherwise if the DIRENT was not found then an error code
is set and control falls through to delexit:

  delexit: shifts the result into DF, restores the consumed registers and
then return control back to the caller.

  delfile: closes the directory file and then calls readsys: to load the
sector in R8:R7, set by the call to searchdir:.  The offset in R9, also
returned by searchdir: is then added to the system DTA address and then
incremented to point to the flags field of the DIRENT.  Bit 0 is checked
to see if it is high, if so then this DIRENT is for a directory and 
cannot be deleted by this function, so control is transferred to delfildir:
to report the error.

  delgo: retrieves the starting lump number from the DIRENT and then zeroes
the first 4 bytes of the DIRENT, thus marking it as deleted.  writesys: is
then called to write the directory sector back to disk.

  delchain: is then called in order to deallocate the lump chain for this
file.  The result code is set to success and control is transferred to 
delexit: to cleanup and return to the caller.

-----------------------------------------------------------------------------

exec:         Execute a program

  This routine is the destination of the o_exec API call and is used to
execute a program.

  f_ltrim: in the BIOS is called in order to remove any leading spaces form
the program name.  The address is then copied into RA, the arguments pointer.

  execlp: loops over the program name looking for either a terminator or a
space.  Once either has been found then is is changed to 00.  If the last
byte was a terminator then RA is backed up to point a the terminator, 
otherwise RA is left pointing at the first byte of the program arguments.

  execgo1: sets rd to intfildes, the system's internal FILDES and then
calls open: in an attempt to open the requested program file.  If the file
could not be opened then DF is set to indicate an error and control is
returned to the caller.

  At opened: the file was successfully opened.  The first 6 bytes of the
file need to be read in order to determine how to load the file.  RF is
set to the system scratch area and read: is called to read the 6 byte
executable header from the file.

  Next the first 2 bytes read are placed into RF in preparation for 
reading the rest of the file.  The next 2 bytes, the load size, is loaded
into RC and read: is then called in order to load the rest of the program
file into memory.

  RF is then set to progaddr, the address where the call is made to the
program.  The start address, the last 2 bytes of the executable header,
are transferred to progaddr. and then scall is executed in order to start
the program.

  If the program returns normally using sret, then DF will be cleared to
indicate successful program execution and control then returns to the
caller.

-----------------------------------------------------------------------------

execbin:      Execute a file from /bin

  This function is used to execute a program located in the system default
execution directory, usually /BIN.

  First consumed register are saved and then execdir: is called in order to
open the system default execution direcotry.  RF is set to point to the
scratch area and searchdir: is called to see if the desired executable can
be found in the default directory.  If the file was not found then a jump
is made to execfail: in order to signal an error, cleanup and return to the
caller.

  If the file was found then close: is called in order to close the directory.
RD is then set to point to the internal FILDES at intfildes  and setupfd:
is called in order to setup the FILDES on the now opened executable file.

  Consumed registers are recoverd and control jumps to opened: (in exec:)
to continue loading the executable file.

  execfail: signals an error and then jumps to openexit: (in open:) to clean
up and return to the caller.

-----------------------------------------------------------------------------

exexdir:      Open /BIN

  This command is used to open the systems default execution directory, 
normally /BIN.

  execdir: starts by saving the callers pathname pointed to by RF. and
then resetting RF to point to the default directory.  This is set to
/BIN by default.

  control is then passed to findcont: (in finddir:) to open the actual
directory.

-----------------------------------------------------------------------------

finalsl:      Make sure a name has a final slash

  This function is called by the directory functions to enforce the pathname
having a final slash.

  First the original value of RF is saved.

  finalsllp: loops over the values pointed to by RF until a 0 terminator is
found. then RF is decremented to the last nonzero value of the name and
checked to see if it is a / character.  If it is then control is passed to
findalgd:
  
  If not then the terminating zero is replaced with a / character and then
the next character is set as the zero terminator.

  finalgd: recovers the original RF value and returns to the caller.

-----------------------------------------------------------------------------

finddir:      Find a directory

  This function is used to create a FILDES for a specified directory path.
This function can work with both absolute as well as relatvie pathnames.

  finddir: starts by calling openmd: which opens the master directory and
returns RD as a FILDES to it.

  Then the first byte of the request pathname is checked to see if the
pathname is absolute, meaning it starts with a /, or from the root 
direcotry.  If the first byte is a / then control is transferred to
findabs:

  If the pathname does not start with a / character, then the path is
relative to the current path.  In this case the requested pathname is
saved and RF is reset to point to path which is Elf/OS' current working 
path.

  findcont: checks the first byte of the pathname for a / and moves 
past it if it is there.

  Next follow: is called in order to walk down all of the directories
in the current pathname.  The result code from follow: is saved in RE.0
and then the original callers pathname is reset in RF.  Then the result
code from follow: is retrieved from RE.0 and checked to see if a valid
directory was the result of the follow, if not then a jump to error: is
made which will end up returning to the caller with an error.

  At this point RD has the FILDES for the final directory listed in the
current working directory and control is transfered to findrel:

  findabs: does nothing more than remove the initial / from an abosute
path and then falls through to findrel:

  when findrel: is reached RD either has the FILDES for the Master Directory
in the case of an absolute pathname, or the RD of the last direcotyr name
specified in the system path.  RF is pointing again to the caller's pathname
and follow: is called to continue walking down the directories in the 
caller's pathname.  If follow: returns in error then the pathname could not
be completely traversed and control is passed to error: which will return
the error to the caller.

  If not errors occured up to this point then RD holds the directory where
the final name is located and RC is pointing to the first character in the
pathname that is a filename and not a directory name.  DF is then cleared
to indicated that the pathname was found and control is returned to the
caller.

-----------------------------------------------------------------------------

findsep:      Split pathname at separator

  This routine will split a pathname into 2 separate parts.  The separation
occurs at the first occurance of the / path separator character.

  findsep: starts by making a copy of RF into RC.  RF is returned as its 
original value, or the directory name before any path separater.

  findseplp: first reads a byte from the pathname and checks to see if it
is less or equal to a space, meaning the end of the pathname was found
before a separator was.  In this case control is transferred to findsepno:
otherwise the character read is compared to the path separator character /.
If the character does not match the separater then control passes back to
findseplp: to test the next character.

  When the path separator is found then the separator is replaced with a
00 byte in order to terminate the name pointed to by RF.  RC is then 
incremented to point to the name following the separater.  DF is then
cleared to indicate that a separator was found, meaning that the name
RF is pointing to is a directory name and not a filename.  Control then
returns to the caller.

  findsepno: is jumped to if a whitespace character was found before a
separator was.  in this case RF is pointing at a filename and not a 
directory name, so nothing happens to the pathname buffer and control
returns with DF set to indicate a non-directory name.

-----------------------------------------------------------------------------

follow:       Follow a directory tree

  The purpose of this function is to find and open the last directory in
a supplied pathname.

  follow: first calls findsep: to see if there are any directory separator
characters.  If none are found then RD is already open at the final
directory of the path so a jump is made to founddir: where DF is cleared
to indicate success and then control is returned to the caller.

  The address following the separator is saved  and then the directory
name before the separator is transferred to RC before searchdir: is called
to see if the name exists in the current directory.  The pathname is 
recovered and the terminator is replaced with the path separator character.
If searchdir: found the name then control is transferred to finddir1:
otherwise the path is broken and an errnofnd is set and control is 
transferred to error:

  At finddir1:, searchdir: reported that the file existed so now it must
be determined if the file is a directory.  So RF is moved forward to point
at the flags field of the DIRENT and bit 0 is checked to determine if the
current DIRENT is for a directory.  If it is not then an invalid
directory error will be raised.

  At finddir2: setupfd: is run to setup the FILDES for the newly opened
directory.  The next portion of the path is moved into RF and a branch
is made back to follow: to move through the next directory name.

-----------------------------------------------------------------------------

freedir:      Get a free directory entry

  This function is called in order to find an available DIRENT in the 
currently opened directory.

  first R8:R7 is set to zero and seek: is called to move the current file 
pointer of the directory back to the beginning.  RB:RA is then set to 0
to mark the directory location.

  newfilelp: is the loop that examines the directory file looking for an
emptry DIRENT.  First RF is set to point to the system scratch area and
read: is called to read the next 32 bytes, size of a DIRENT, into the
scratch area.  The bytes read count is checked to see if the end of the
directory was encountered, and if so a jump is taken to neweof:

  Next the first 4 bytes of the read DIRENT are checked to see if is 
allocated or not.  If any of the bytes are non-zero then the DIRENT is
already in use and control is transferred to newnot:  Otherwise if all
4 bytes are 00s, then control is passed to neweof: to setup the new 
DIRENT.

  newnot: copies the current file pointer into RB:RA in preparation for
the read of the next DIRENT. RB:RA always has the file pointer position
at the beginning of the DIRENT currently being looked at.  RD is then
moved back to the beginning of the FILDES and control passes back to
newfilelp: to check the next DIRENT.

  neweof: copies the offset of the unallocated DIRENT from RB:RA to R8:R7
and seek: is called to move the file pointer back to the beginning of the
available DIRENT.  A success code is placed into D and then control
returns to the caller.

-----------------------------------------------------------------------------

freelump:     Find a free lump

  This function is called in order to obtain a free lump.  It starts by
saving all the consumed registers and then calling sector0: in order to load
the system data sector into memory.  The address of the Master Directory is
retrieved from the sector into RB.  Note: this function currently relies on
the Master Directory immediately following the LAT sectors.  This requirement
will be removed in future kernel versions.

  Next R8:R7 is set to sector 17, the first sector of the LAT table.  RD is
then set to use sysfildes, the system FILDES.

  freelump1: is the start point of the main loop of this function.  It 
starts by comparing the current sector in R8:R7 to the Master Directory
sector in RA:RB.  If the current sector does not equal the Master Directory
sector then control is transferred to freelump2: in order to scan the 
sector for a free entry.  If the sectors numbers match then the error code
is set and control passes do freelumpe:.

  freelumpe: shifts the result code into DF, then restores the consumed 
registers before retuning control back to the caller.

  freelump2: starts by calling rawread: in order to load the current LAT
sector into the system DTA.  R9 is set to point the beginning of the DTA,
or first entry in the sector and RC is set to 256, the number of entries
per sector.

  freelump3: retrieves the value from the current entry pointer, poined to
by R9, and determines if the entry is 0000h.  If the entry non-zero then
control is passed to freelump4:  Otherwise, the DTA's address in memory,
100h is subtracted from R9 in order to get the entry offset and then
secofslmp: is called to convert the LAT sector number/entry offset to the
actual lump number represented by this entry.  The result code is set to
success and control is transferred to freelumpe: to clean up and return.

  freelump4: moves the current entry forward to the next entry, 2 bytes. and
RC, the entry counter, is decremented and checked to see if all the entries
in the current sector have been checked.  If not then control passes back
to freelump3: to continue checking LAT entries in the current sector.
Otherwise the current LAT sector in R8:R7 is incremented and control passed
back to freelump1: to load in the next LAT sector to be checked.

-----------------------------------------------------------------------------

getfddrof:    Get dir offset from file descriptor

  This function retrieves the directory offset from the FILDES pointed to
by RD.  The dir offset is located at offset 13 in the FILDES, so RD is
incremented by 13 before the next 2 bytes are read into R9.  fdminus13: 
then moves RD back to the beginning of the FILDES before returning.

-----------------------------------------------------------------------------

getfddrsc:    Get dir sector from file descriptor

  This function obtains the directory sector entry of the FILDES pointed to
by RD.  The dir sector is located at offset 9 in the FILDES, so RD is
incremented by 9 before reading the next 4 bytes into R8:R7.  fdminus12:
will then move RD back to the beginning of the FILDES before returning.

-----------------------------------------------------------------------------

getfddta:     Get DTA from file descriptor

  This functions retrieves the DTA address from the FILDES pointed to by
RD.  The DTA is at offsets 4 and 5 in the FILDES, so RD is incremented by
4 and then the next 2 bytes are copied into RF.  fdminus5: will then move
RD back to where it was.

-----------------------------------------------------------------------------

getfdeof:     Get EOF from file descriptor

  This function retrieves the 2 byte EOF value from the FILDES pointed to
by RD.  The EOF is located in offsets 6 and 7 of the FILDES, so RD is 
incremented by 6 and then the next 2 bytes copied into RF.  fdminus7: then
moves RD back to the beginning of the FILDES before returning.

-----------------------------------------------------------------------------

getfdflgs:    Get flags from file descriptor

  This function retrieves the file flags from the FILDES pointed to by RD.
The file flags are located at offset 8, so RD is incremented by 8 before
retrieving the value into D.  fdminus8: preserves the value in D by moving
it to RE.0 and then moves RD back to the beginning of the FILDES.  RE.0 is
then copied back to D before returning.

-----------------------------------------------------------------------------

getfdofs:     Get offset from file descriptor

  This function retrieves the current file offset from the file descriptor
pointed to by RD.  The current file offset is in the first 4 bytes of the
FILDES and so this function just copies the first 4 bytes from the FILDES
into R8:R7.  At fdminus3: RD is decremented by 3 bytes so that RD is
left at the same position as when the function was called

-----------------------------------------------------------------------------

getfdsec:     Get current sector from file descriptor

  This function retrieves the current sector from the FILDES pointed to by
RD.  The current sector is located at offset 15 in the FILDES, so RD is
first incremented by 15 then the next 4 bytes are copied into R8:R7.
fdminus18: then moves RD back to the beginning of the FILDES before returning.

-----------------------------------------------------------------------------

getsecofs:    Get current sector/offset

  This function returns the current sector in the FILDES's DTA as well as
the offset into this sector where the file pointer is.

  The sector offset is the lowest 9 bits of the current file pointer,
therefore RD is moved to offset 2, or 3rd byte of the file pointer and
the value is retrieved.  Only bit 0 is needed from this byte so it is ANDed
with 1 to strip off the higher 7 bits before it is stored into R9.1. Then
the next byte, or byte 4 of the file pointer is read and placed into R9.0.
At this point R9 has the offset into the current sector.

  Next RD is moved to offset 15 in the FILDES and then the 4 bytes of the
current sector field are copied into R8:R7.

  RD is then restored back to the beginning of the FILDES and control is
returned to the caller.

-----------------------------------------------------------------------------

gettmdt:      Get time and date from BIOS

  The purpose of this routine is to retrieve the current date and time from
the BIOS and then convert it to the format used in DIRENTs.  If the BIOS
reports that an RTC is not part of the system then a default date/time is
provided.

  gettmdt: starts by saving consumed registers and calling f_getdev: in the
BIOS to determine if an RTC is present.  If no RTC is available then control
passes to no_rtc to set the default date/time.  Otherwise f_gettod: in the
BIOS is called to retrieve the current data/time from the RTC.

  The code at rct_cont: takes the various pieces of data returned by the
BIOS and performs a series of shifts and combinations to pack the data
into the DIRENT data/time format.

  gettm_dn: recovers consumed registers and returns to the caller.

  no_rtc: is used when no RTC is present in the system.  This sets RF to a
default data and time, normally set at compile time to the date the 
particular kernel came into existance, 2/20/2006 as an example for the 
0.2.7 kernel.  Control is then transferred back to rtc_cont: in order to
pack the date/time into the DIRENT format.

-----------------------------------------------------------------------------

incofs:       Increment current offset in fildes

  This function is called by read: and write: in order to update the current
file pointer.  This routine checks to see if a sector or lump boundary is
crossed and loads the next sector into the DTA if needed.

  incofs: starts by moving RD to the LSB of the current file offset.  1 will
be added to this value and the result stored back as well as kept in RE.0
for later.  The addition is then propagated across the rest of the bytes
that make up the current file pointer.

  The value in RE.0 is then retrieved, this was the incremented LSB of the
current file pointer, and checked for nonzero values.  If it is nonzero
then the current file pointer has not crossed a sector boundary so DF will
be cleared to indicate no sector was loaded and control returned to the 
caller.

  If the low byte was zero then the 3rd byte of the file pointer needs to
be checked as well.  If bit 0 of the 3rd bytes is also zero then the file
pointer moved across a sector boundary.  Otherwise if it is nonzero, then
the file pointer is still in the same sector, so control is transferred to 
incofse1: to signal no sector read and return to the caller.

  If a boundary was crossed then this routine continues by saving consumed
registers.  The lump shift mask at lmpmask is used to mask the bytes from
byte 3 of the offset and then stored back in RE.0.  Next RD is moved to point
to the current sector field of the FILDES where it is then transferred to
R8:R7 before being moved back to the beginning of the FILDES.

  Byte 1 of the current file pointer, which was ANDed with the lump mask,
is retrieved from RE.0 and checked for nonzero values.  If zero then the
file pointer crossed a lump boundary and control is transferred to incofslmp:
otherwise R8:R7, the current sector, is incremented to the next sector and
rawread: is called to load the new sector into the DTA.

  incofse2: recovers registers used by the boundary crossing code and then
sets DF to indicate that incofs: loaded a new sector into the DTA.  Control
is then transferred back to the caller.

  If a lump boundary was crossed then control was transferred to incofslmp:
where additional registers are saved and a call is made to sectolump: to
convert the current sector to the lump number that contains this sector.

  readlump: is then called in order to read the LAT entry corresponding to
the current lump.  lumptosec: is then exectud to find the sector number
that is found at the beginning of the new lump.  This sector is then read
into the DTA by calling rawread:

  readlump: is called again on the new lump number to retrieve its value.
RD is moved to the flags field of the FILDES and the read lump value is 
checked for 0FEFEh, the end of chain code.  If the read value is something
other than 0FEFEh, meaning there is at least 1 lump folloing the new 
current lump, then control is transferred to incofs3: where the FILDES flags
are set to indicate that the file pointer is not in the last lump before
control is transferred to incofs4:

  If the new lump LAT entry is 0FEFEh, then the flags are updated to 
indicate that the file pointer is within the last lump of the file.

  incofs4: restores the registers that were consumed by the boundary
crossing code and then jumps to incofse2: to finish cleaning up and
return to the caller.

-----------------------------------------------------------------------------

lmpsecofs:    Convert lump number to latSector/latOffset

  This function is used to find the LAT sector and LAT offset for the givin
lump number.  The formulas for these in a type 1 filesystem are:

  LAT_sector = (lump / 256) + 17
  LAT_offset = (lump MOD 256) * 2

  This function calculates the LAT_offset first byte taking the value in RA
and multiplying it by 2 using a 16-bit left shift.  Only RA.0 is needed
for this operation since we want the lump number MOD 256, or to put it 
simply, just the low byte of RA.  The first 8-bit shift takes the value from
RA.0 shifts it and puts it into R9.0.  DF holds the bit that was shifted
out from RA.0.  By loading D with 0 and then performing the SHLC we are
shifting the high bit of RA.0 in and thus propagating the carry from the
multiply by 2.  After this is complete R9 will have a value from 0 to 510,
the LAT offset for the given lump.

  Next to compute the LAT sector we take the high value of RA, which implies
the / 256 and add 17 to it before storing into R7.  In order to propagate
any carry from the addition we add with carry into 0 and place the result
into R7.1.  Since in type 1 filesystems the LAT sector will always be under
65536, R8 is just zeroed.

  At the conclusion R8:R7 have the LAT sector containing the specified lump
entry and R9 has the offset into that sector where the lump entry is found.

-----------------------------------------------------------------------------

lmpsize:      Set shift count variable for current lump sector size

  The purpose of this routine is to determine how many shifts are needed
to convert sector numbers to lump numbers and vice versa.

  The sectors per lump value is stored in the SDS, so sector0: is called
in order to load the SDS into the system DTA.  The SDS offset for the
sectors per lump value is 010Ah.  Since the system DTA is at 0100h, 0100h
needs to be added to point to the 020Ah which is where the value can be
found.  RF is set to 020Ah and the value is then read into RF.0

  RE.0 is set to zero to indicate the number of shifts needed to convert
sector/lump numbers.

  The loop at lmpsize1: first increments RE.0 to indicate another needed
shift and then the sectors per lump value in RF.0 is shifted to the right.
If RF.0 is not zero then additional shifts are needed so control is passed
back to the beginning of the loop at lmpsize1: to perform another shift
operation.

  RE.0 is then decremented by 1 in order to produce the correct shift count.
if sectors per lump is 8, then RE.0 will equal 3.

  lmpshift is the kernel variable that is used to store the lump shift size,
so its address is set into RF and then the shift count is written to the
variable.

-----------------------------------------------------------------------------

loadsec:      Load current sector from fildes

  This function is normally called after a seek was performed on a FILDES.
Since a seek could leave the file pointer in a sector other than the one
currently in the DTA, this function is called in order to load the sector
that corresponds to the current file pointer into the DTA.

  The function starts by saving consumed registers and then retrieving the
current file position shifted right by 9.  Each sector is 512 bytes, or 
9 bits of the file position.  After the shift R8:R7 will be the current
file pointer MOD 512, or the linear sector number where the file pointer
is located.

  Next the relative lump number of the file pointer is needed, so sectolump:
is called to obtain the relative lump number and stored into RC.  startlump:
is then called to get the first lump of the file.

  ldseclp: checks to see if RC has been decremented for as many lumps as
there are preceeding the lump the current file pointer is in.  If RC is
not zero, then more lumps need to be walked, so a jump is made to ldsecgo:
in order to move to the next lump in file.  Once the correct lump is located
then control falls through to ldsecct:

  When ldsecct: is reached RA will have the lump number of the lump where
the current file pointer is pointed.  At this point the physical sector
needs to be located and loaded into the DTA.

  ldsecct: starts by determining the sector offset within the lump.  This 
will be a number from 0 to the number of sectors per lump value.  lumptosec:
is then called in order to convert the current lump number to the sector
address that is at offset 0 in the lump.  The lump offset is then added to
this value in order to obtain the actual sector where the file pointer
is located.

  rawread: is then executed in order to load the correct sector into the 
DTA.  cklstlmp: is called in order to set the last lump flag and check if
the seek position is beyond the current EOF.  If the current position is
beyond the EOF, cklstlmp: will update the EOF field in the FILDES.

  Consumed registers are then recovered and control passed back to the
caller.

  ldsecgo: starts by saving the current lump number and calling readlump:
in order to obtain the next lump in the chain.  The next lump is checked for
the end of chain code of 0FEFEh.  If not then control is transferred to 
ldsecgo2: in order to decrement the lump counter and then jump back to
ldseclp: to continue walking along the lump chain.

  If the end of chain code was found then the current file pointer is beyond
the current EOF, which is allowed.  Elf/OS will extend a file up to the
file pointer.

  The last lump number is retrieved as the starting point of where additional
lumps need to be appended.

  ldsecadlp: is the loop that will continually append new lumps to the end
of the file until the lump counter in RC is brought to zero.  It starts
by calling append: to append the new lump to the file and then calling
readlump: in order to get the next lump number in the chain, or the lump
number of the just added lump.  RC is then decrementd and and checked to 
see if enough lumps have been added.  Control keeps passing to ldsecadlp:
until RC reaches zero, indicating the file now has the lump number holding
the current file pointer.

  The EOF field is in the FILDES is set to zero, indicating that the EOF 
for the file is now the fist byte of the last loaded lump.  The file 
pointer could still be beyond this EOF, but it will be checked and set if 
needed by ldsecct:

  RF is then recovered and control passed to ldsecct: in order to locate
the sector where the file pointer is located.

-----------------------------------------------------------------------------

lumptosec:    Convert lump number to first sector number in lump

  This function will take a lump number and return the first sector number
for the lump.

  Starting sector numbers are obtained by multiplying the lump number by 
the number of sectors per lump.  Since sectors per lump must be a power of
2, it is possible to use left shifts in order to perform the multiplications.

  The value in lmpshift contains the number of shifts that are needed in 
order to convert a lump number into the starting sector number, so the 
value in lmpshift will be read into RE.0 as a loop counter.

  Since the result will be in R8:R7, the lump number in RA is copied into
R7 and R8 is zeroed.

  sectolmp1: performs a 32 bit left shift on the value in R8:R7.  After
the shift is complete RE (the loop counter) is decremented and checked to
see if it is zero.  If all the shifts have not been completed then control
is transfered back to sectolmp1: for the next shift.

  Since the shifts have been operating on R8:R7, which are also the return
registers, no copy is needed of the result, so the routine just returns.

-----------------------------------------------------------------------------

mkdir:        Make a directory

  This routine is the destination of the o_mkdir API call and is used to
create a new subdirectory on the filesystem.

  first consumed registers are saved and then a copy of the pathname is 
made.  the loop at mkdirlp: searches for the end of the pathname.  When it
is found the last character of the pathname is checked to see if it is a /
character, and if it is it is removed from the pahtname.

  At mkdir_go: RD is set to intfildes, the systems temporary FILDES.  RF
is then saved and a call to o_open: is attempted to open the specified
pathname.  If the file was not able to be opened, meaning it does not exist
then control is transferred to mkdir1: to continue.  Otherwise if the 
file could be opened, the file exists.  It is not allowed to overwirte a
file with a directory, so an error condition is set, consumed registers
are restored and control passes back to the caller.

  If the file did not exist then control is at mkdir1: which calls
finddir: in order to get the directory portion of the pathname opened
in a FILDES.  freedir: is then called in order to find a free entry in the
parent directory of the new one.  freedir: will extend the directory if
a blank entry is not found, so freedir: will always return with a valid
DIRENT.

  create: is then called in order to create the new directory file.  R7 is
set to 1 when create: is called so that the new file will be marked as a
directory as opposed to a standard file.

  Since create: leaves the file in an open state, close: is called in order
to close the FILDES and finalize the creation of the directory.  Consumed
registers are then restored and control is returned to the caller with DF
cleared to indicate a success.

-----------------------------------------------------------------------------

open:         Open a file

  This function is the destintion of the o_open API call and is used to
open/create a file.

  open: starts by calling validate: in order to validate that the filename
is valid, meaning it consists of the right characters, not zero length and
not too long.  If the filename is invalid that a jump is made to noopen:
to return to the caller in error.

  Consumed registers are saved and then finddir: is called in order to
open the final directory in the path to the filename.  searchdir: is then
called to find the DIRENT for the requested file.  If the file could not
be found then a branch is taken to newfile: in order to see if the file
can be created.

  Next the open flags are checked to see if the truncate on open mode was
selected.  If bit 1 of the flags is not set, then truncate was not requested
so control is transferred to opencnt: to finish opening the file.

  If the truncate option was selected then the first lump number of the 
newly opened file's DIRENT is retrieved and delchain: is called in order
to remove all the lumps from the file except the first.  Then the file's
first lump LAT entry is set to 0FEFEh to indicate the end of chain. and the
EOF in the DIRENT is set to zero.

  opencnt: calls close: in order to close the directory where the file was
opened.  Needed consumed registers are recovered and setupfd: is then 
called to complete the setup of the newly opened FILDES.

  Bit 2 of the open flags are then checked to see if the append mode was
selected.  If not, then control passes do opendone: otherwise seekend: is
called to seek the file to the EOF and then loadsec: is called in order
to load the sector containing the EOF into the DTA.

  opendone: clears DF to indicate that the file was opened successfully and
then falls through to openexit:

  openexit: recovers consumed registers and then returns to the caller.

  If the file was not found during the call to searchdir: then control is 
transferred to newfile: which checks bit 1 of the create flags to see if 
the create option was selected.  If creation was allowed then control will
pass to allow: in order to create the new file.  Otherwise DF is set to
indicate an open error and control passes to openexit: to cleanup and 
return to the caller.

  allow: starts by saving RC to prevent freedir: from destroying it, freedir:
is then called in order to allocate a DIRENT to the new file.  needed
registers are recovered and create: is called in order to create the new
file in the filesystem.  DF is then cleared to specify that the file was
successfully opened and control passes to openexit: to clean up and return
to the caller.

-----------------------------------------------------------------------------

opendir:      Open a directory

  This function is the destination of the o_opendir command and is used
to open a directory as a FILDES.

  first consumed registers are saved and then finddir: is called.  findir:
will return RD as an open FILDES to the directory portion of a filename and
will also return RC at the first character of the name following the 
directory path.  RC is capied back into RF as the first character following
valid directory names.

  Consumed registers are then restored and control transfers back to the
caller.

-----------------------------------------------------------------------------

openmd:       Open master directory

  This routine is used in order to open the Master Directory as a file.  It
returns a FILDES that is opened on the Master Directory.

  First consumed registers are saved and then sector0: is called to load
in the System Data Sectors, which contains the DIRENT for the Master
Directory.  RD is then set to poing the mdfildes, the FILDES that is
dedicated for use by the directory functions.

  304 is added to the system DTA address in order to allow RF to point to
EOF field in the Master Directory's DIRENT.

  The first 4 bytes of mdfildes are cleared in order to position the current
file pointer at the beginning of the Master Directory.

  The next 2 bytes of mdfildes are set with mddta, the DTA that is dedicated
for use by the directory functions.  Following the DTA address the 2 bytes
of the Master Directory's EOF field are copied into mdfildes.

  Then the next 4 bytes, the directory sector for the DIRENT, and then the
next 2 bytes are set to 300 which is the offset of the DIRENT.  The next
4 bytes, the current sector field, are set to FFh to indicate that the DTA
currently does not hold a sector.

  RD is moved back to the begining of mdfildes and RF is moved to point to
the starting sector field in the SDS, which is still in the system DTA.
The starting sector is loaded into R7 and then rawread: is called in order
to load the first sector of the Master Directory.

  Consumed registers are then recovered and control returned to the caller.

-----------------------------------------------------------------------------

rawread:      Read a sector from disk

  This function is called whenever Elf/OS needs to read a physical sector
from disk.  It will first call secloaded: to determine if the requested
sector to read is already in the DTA of the specified FILDES.  If the
requested sector is not the same as the requested sector then control will
be transferred to rawread1: otherwise no sector needs to be read so the
control is passed back to the caller.

  At rawread1: a call is made to checkwrt: to see if the sector currently
loaded in the DTA has been modified.  If it has been modified, bit 0 of the
FILDES flags is set, then checkwrt: will write the sector to disk.

  Consumed registers are then saved and RD is moved forward 4 bytes in order
to retrieve the DTA address into RF, the register that the BIOS expects
for the read buffer.  R8:R7 specifies the sector number for the read.
R8.1 is not used for sector addresses, but for the device and access mode,
so R8.1 is set to 0E0h in order to select the master device and to set it
for LBA mode.  The BIOS f_ideread: is then called to perform the physical
read of the requested sector.

  RD is then incremented to point to offset 8.  RD is incremented twice 
since it is already pointing to offset 6 after the read of the DTA address.
Bit 0 of the flags is reset to indicate that the currently loaded sector
has not been modified.

  RD is then incrmented by 7 more so that it is pointing at the current
sector field of the FILDES.  The just read sector number is then written
into the 4 byte current sector field.

  Consumed registers are then restored and control is transferred back to
the caller.

-----------------------------------------------------------------------------

rawwrite:     Write a sector to disk

  This routine writes the sector in the specified FILDES's DTA.  First a
check is made to determine if the requested write located in R8:R7 is a 
valid sector address.  A sector address of 0ffffffffh is not valid.

  If the sector number is valid then control is transfered to rawwrite1:
where consumed registers will be saved.  The DTA field is at offset 4 of
the FILDES, so RD is moved forward 4 bytes to point to the FILDES where it
is then retrieved into RF, the register the BIOS expects to find the 
sector data to be written.

  The BIOS expects the sector to write number in R8:R7 which is how it is
passed into this routine.  High R8 is not used for sector addressing but
rather to select device and access mode, so R8.1 is saved and then set to
0E0h which selects the master device and the LBA mode.  Then the BIOS
f_idewrite is called in order to write the sector out to disk.

  Next RD is incremented to the FILDES flags at offset 8 and the sector
written flag is cleared to indicate that the sector in the DTA now matches
what is on disk.

  Next RD is incremented to point to the current sector field at offset 15
so that the sector number can be updated to match the physical sector number
that was written.  Under normal circumstances this field will start out as
the requested sector to write, but there may be special circumstances where
a sector needs to be written to somewhere other than where it was originally
read from.

  All consumed registers are then restored back to their original values and
the routine returns to the caller.

-----------------------------------------------------------------------------

read:         Read bytes from file

  This function is the destination of the o_read API call.  Its purpose is
to read bytes from the open FILDES pointed to by RD.

  First consumed registers are saved and then settrx: is called in order to
setup R9 to point to the correct address in this FILDES's DTA.  The bytes
read counter is then cleared and main read loop begins.

  readlp: is the main read loop.  It first checks RC to see if all the 
requested bytes have been read or not.  If there are more bytes to read
then control is passed to read1:  otherwise the bytes read count is moved
from RB to RC and the consumed registers are restored before returning to
the caller.

  read1: calls checkeof: in order to see if the current file pointer is
pointing at the EOF byte.  If not then control is transferred to read2:.
Otherwise if file is at the end, then RC is set to read no more bytes and
control is passed back to readlp: which will find no more bytes need to be
read and return to the caller.

  read2: reads a byte from the DTA, pointed to by R9, and moves it to the
callers's buffer, pointed to by RF.  incofs: is then called in order to
add 1 to the current sector pointer in the FILDES.  If incofs: reports 
that a new sector was not loaded then control passes back to readlp: to 
read the next character.  Otherwise settrx: is called in order to resetup
R9 to point to the beginning of the newly read sector data.

-----------------------------------------------------------------------------

readlump:     Read a value from a lat entry

  This routine is called whenever a LAT entry needs to be read.  The LAT
table begins in sector 17 and in type 1 filesystems contains 256 LAT entries
per sector.

  First lmpsecofs: is called to convert the lump number into the LAT sector/
LAT offset then RD is set to point to sysfildes, the system FILDES, and
rawread: is called to read the needed LAT sector into the system DTA.

  The location of the system DTA (0100h) is added to the LAT offset in 
order to determine the memory address in the system DTA where the LAT entry
is located.  This value is then read into RA for return to the caller.

  Consumed registers are restored and control passed back to the caller.

-----------------------------------------------------------------------------

readsys:      Read a sector using system fildes

  This routine is used by Elf/OS whenever it needs to read system related
sectors.  The system DTA is located at 100h and sysfildes is the FILDES that
is used whenever Elf/OS wants to use the system DTA.  Unlike normal FILDES's
sysfildes does not really describe an actual file, but is used to track which
sector is loaded into the system DTA and whether or not it has been modified.
This FILDES is needed because the rawwrite: and rawread: functions work off
of values in a FILDES.

  First RD is saved so that it can be reset with the address of sysfildes.
rawread: is then called to read the reqested sector from disk. After the 
sector has been read the original RD is restored and control is transferred
back to the caller.

-----------------------------------------------------------------------------

rename:       Rename a file

  This routine is the destiantion of the o_rename API call and is used to
rename a file.  This routine renames a file by altering its name in its
DIRENT.  Since this routine modifies in place, it does no allow a file to
moved from one diretory to another.

  rename: starts by saving all the registers that it consumes and then calls
finddir: in order to open the directory which cotains the file.  After the
directory has been opened then searchdir: is called in order to locate the
DIRENT for the source filename.  If either finddir: or searchdir: fail then
the directory file is close and DF is set to indicate an an error. Control
is then transferred to delexit: (in delete:) to cleanup the registers and
return to the caller.

  renfile: closes the directory file since it is no longer needed.  From 
this point forward direct sector read/writes will be used in order to
perform the rename.

  Since searchdir: leaves R8:R7 set to the sector containing the DIRENT for
the sourcefile, readsys: can be called to read that sector into the system
DTA.

  R9, the offset into the directory sector as set by searchdir: is then
added to the address of the system DTA (0100h) in order to dertermine where
in physical memory the DIRENT is now located.  The add actuall adds 010Ch
in order to make R9 point to the filename field of the DIRENT.

  renlp: then copies the bytes for the passed new filename to the filename
field of the DIRENT.  Once all of the bytes have been copied then writesys:
is called in order to write the diretory sector back to disk.

  The return value is set to 0 in order to indicate that no error occurred
during the rename.  Control is then transferred to delexit: (in delete:) 
to restore the consumed registers and return to the caller.

-----------------------------------------------------------------------------

rmdir:        Remove a directory

  This routine is the destination of the o_rmdir API call and its purpose
is to remove a subdirectory from the filesystem.  A directory can only be
removed if it contains no allocated entries.

  rmdir: starts by calling finalsl: in order to make sure that the caller's
passed pathname has a final slash on it.  then all consumed registers are
saved.

  o_opendir: is then called in order to open the specified directory as a
file.  If the directory could not be opened then control falls through to
rmdirerr: to report the error back to the caller.  If the directory was 
correctly opened then control is transferred to rmdirlp: in order to 
process the directory.

  rmdirerr: sets DF to indicate an error and then jumps to delexit: (in
delete:) to clean up and return to the caller.

  rmdirlp: loops over the file reading all the DIRENT's looking for any
DIRENT's that are still allocated.  After setting up the read count in RC
to 32, number of bytes in a DIRENT, and setting the destination buffer,
read: is called to read in the next DIRENT:  If the read bytes count is
not 32, then the end of the directory was reached and control passes to
rmdireof:  If it made it this far, then there were no allocated DIRENTs.

  after the next DIRENT is read the first 4 bytes of the DIRENT are checked
for nonzero values.  If any of these 4 bytes are nonzero then this is an
allocated DIRENT and rmdir: will jump to rmdirno: where a non emtpry
directory error codes is set and then control passes to rmdirerr: to return
to the caller.

  After the entire directory is scanned and no active DIRENTs were found,
getfdrsc: and getfdrof: are called in order to get the directory sector
and offset of the DIRENT hodling the directory to be deleted's name.  
readsys: is then called to read the actual directory sector.  R9 will have
the system DTA of 0100h added so that R9 is pointing at the memory address
where the DIRENT for the directory to be deleted is loaded.  A jump is then
made to delgo: (in delete:) to complete the deletion.

-----------------------------------------------------------------------------

searchdir:    Search a directory for an entry

  This function is used in order to find the DIRENT for the filename pointed
to by RC.  This function is called with the directory opened and an
appropriate FILDES for the directory is passed into this function.  The
results of this function are to have the directory sector of the requested
DIRENT in R8:R7 and the offset in R9.  The directory entry itself will also
be stored at the buffer pointed to by RF.

  This function starts by saving consumed registers and making copies of the
destination buffer address and filename address.

  searchlp: is the main loop that will read the DIRENT's in the passed 
directory file searching for the specified filename.  First the current
pointer is obtained by calling getsecofs:.  If the current DIRENT is the
one containing the file, then these will be the values returned as the 
sector and offset of the DIRENT.

  The caller's buffer is then setup and 32 bytes, the size of a DIRENT, are
read into the buffer by calling read:  A check of the returned read count
is checked to see if 32 bytes were read, if not then the end of the directory
was encountered and file was not found, so a jump to searchno: is taken.

  Next the entry that was just read is checked to see if it is a valid
DIRENT, meaning that the first 4 bytes are not all 00s.  If all zeroes
are found, then this is an unallocated DIRENT and we need to go and get
another one, so control is transferred back to searchlp:

  If the last read entry was valid, then the filename passed by the caller
is compared against the filename in the DIRENT.  The filename entry starts
at offset 0Ch.  f_strcmp: from the BIOS is called to perform the string
compare of the filenames.  If the names do not match then control passes
back to searchlp in order to try the next DIRENT in the directory.

  When the names match, then the result is set to 0 in order to indicate
that the file was found.

  At searchex: the result code is shifted into DF and then all the 
consumed registers are recovered before returning to the caller.

-----------------------------------------------------------------------------

secloaded:    Determine if needed sector is already loaded

  This function determines if a reqested sector read refers to the sector
that is already in the DTA for the specified FILDES.

  The current sector number is in offset 15 of the FILDES, so RD is first
saved and then incremented by 15.  At this point R8:R7 is compared to the
four bytes that make up the current sector field.  If any of the bytes
do not match then the sector in the DTA is not the requested sector so
DF will be cleared to indicate that the sector needs to be loaded.

  If all 4 bytes match then DF will be set to indicate that the requested
sector is already in the DTA.

  RD is then recovered and control returns to the caller

-----------------------------------------------------------------------------

secofslmp:    Convert latSector/latOffset to lump number

  This function is used to convert a LAT sector number and LAT sector
offset into a lump number.  For type 1 filesystems the fomula for this is:

  lump = (LAT_Sector - 17) * 256 + (LAT_offset / 2)

  This routine starts by combining the -17 and *256.  Since 8 shifts is the
same as multiplying by 256, and each register is 8 bits in length, by 
taking a value and placing it one byte higher you get the *256.  So
by getting the value in R7 (LSB of the LAT sector) and subtracting 17 we
first have shifted out the LAT table offset and then by putting the value
into RA.1 instead of RA.0 we have performed the 8 shifts and so the multiply
by 256.

  Next we need the LAT offset divided by 2 (Each LAT entry is 2 bytes). 
R9 holds the LAT offset so we will perform a 16 bit shift on it, placing the
result into RA.0.  Since there are 256 LAT entries per LAT sector, this 
maps cleanly into RA.

-----------------------------------------------------------------------------

sectolump:    Convert sector number to lump number

  This function is used to convert the sector number in R8:R7 to the lump
number that contains this sector.

  The conversion of sector to lump is to divide the sector number by the
number of sectors per lump.  Since sectors per lump must be a power of 2 it
is possible to use right shifts to perform the division.

  The value in lmpshift contains the number of shifts needed in order to
convert the sector number to a lump number, so this value is read into RE.0,
which will be used as the loop counter.

  Since the result will be in RA, R7 (the low word of the sector number) is
copied into RA.  R8 is copied into RB

  The shift loop starts at lmptosec1: and performs a right shift operation
on the 32 bit value located in RB:RA.  After the entire 32 bit value has
been shifted, RE (the shift counter) is decremented.  RE.0 is then tested
to see if all the necessary shifts have been completed.  If not then control
is passed back to lmptosec1: to perform another 32 bit shift.

  After the shifts are completed the result is in RB:RA.  In type 1 
filesystms lump values are only 16 bits so RB is discarded and the lump
number is returned in RA.

-----------------------------------------------------------------------------

sector0:      Load sector 0

  This routine is called whenever Elf/OS needs the System Data Sector.

  First the consumed registers R8 and R7 and saved and then set to 00, 
which is the sector number for the SDS.  readsys: is then called in order
to load sector 0 into the system DTA.  R8 and R7 are then restored back
to their original values and control is returned to the caller.

-----------------------------------------------------------------------------

seek:         Perform file seek

  This function is the destination of the o_seek API call.  The purpose of
this routine is the change the current file position in the provided FILDES.

  First the FILDES pointer in RD is moved to the LSB of the current file
position at which point RC is checked to see which seek mode was required.
If the seek mode was not 0, then control is transferred to seeknot0:.
Otherwise the passed offset in R8:R7 is written ino the FILDES as a seek
from the beginning of the file.  Control then falls through to seekcont:

  seekcont: will call loadsec: in order to load the sector containing the
new file pointer position into the DTA.  and then returns control back to
the caller.

  seeknot0: checks to see if seek mode 1, offset from current, was specified,
if not, then control is transferred to seeknot1.

  At seekct2: the value in R8:R7 is added to the offset that is currently
in the current file position field of the FILDES, thus producing a seek
from current location.  After the addition control is transferred to 
seekcont: in order to load the new sector and return to the caller.

  seeknot1: will check for seek mode 2, which is the seek from end.  If the
seek mode was not 2, then control is transferred to seeknot2: which will
restore RD to the beginning of the FILDES and return to the caller.

  Otherwise RD is moved back to the beginning of the FILDES so that seekend:
can be called to move the file pointer to the end of the file.  After the
file pointer is moved to the end of the file by seekend: RD is again moved
to the LSB of the current file pointer and control jumps to seekct2: in
order to add in the caller's offset.

-----------------------------------------------------------------------------

seekend:      Seek fildes to end

  This function will move the current file pointer in the FILDES pointed to
by RD to the end of the file.  This is normally called by seek: or open:.

  First consumed registers are saved and then R8:R7 is cleared for the walk
through the lump chain.  startlump: is then called in order to obtain the 
first lump of the file.  Prior to the main loop of this routine, readlump:
is called in order to obtain the value of the starting lump entry.

  seekendlp: loops over the lumps until it finds the 0FEFEh end of chain
code.  If the end code has not yet been found, then control is transferred
to seekendgo: in order to update the offset being tracked in R8:R7.

  When the end of chain code is found seekendlp: will fall through and
getfdeof: will be called in order to retrieve the file's EOF offset into RF.
The EOF offset in RF is then added into the offset R8:R7 and then setfdofs:
is called in order to write the ending file position into the current file
pointer in the FILDES.  Afterwhich the consumed registers are recovered
and control returns to the caller.

  seekendgo: Is jumped to from the main loop at seekendlp: whenever the
currently worked on lump is not equal to the end of chain code, 0FEFEh.

  seekendgo: must first determine how many bytes there are per lump.  This
is done by setting RF to 0200h, or 512 bytes, then retrieving the lmpshift
count in order to shift the initial size up to the correct size.

  seeklp1: checks to see if all the necessary seeks have been completed or
not, if they are done, then control is transferred to seekendg1: otherwise
RE is deccremented and the size per sector value in RF is multiplied by 2
by left shifting the high byte of RF.  Control returns back to seeklp1: 
until RE.0 indicates that all the shifts have been completed.

  After the offset in R8:R7 is updated then readlump: is called to get the 
next lump entry in the chain before control is sent back to seekendlp: to
continue walking the lump chain.

-----------------------------------------------------------------------------

setfddrof:    Set dir offset in file descriptor

  This functions is used to set the directory offset in the FILDES pointed
to by RD.  The dir offset is located at offset 13 in the FILDES, so RD is
first incremented by 13 before the 2 bytes of R9 are written into the FILDES.
Control is then transferred to fdminus14: (in getfddrof:) to move RD back to
the beginning of the FILDES before returning.

-----------------------------------------------------------------------------

setfddrsc:    Set dir sector in file descriptor

  This functions sets the directory sector field of the FILDES pointed to by
RD.  The dir sector entry is located at offset 9 in the FILDES, so RD is
incremented by 9 before writing the 4 bytes of R8:R7 into the FILDES.
Control is then trasferred to fdminus12: (in getfddrsec) to move RD back to
the beginning of the FILDES before returning.

-----------------------------------------------------------------------------

setfddta:     Set DTA in file descriptor

  This function will set the DTA in the FILDES pointed to by RD to the
address in RF.  The DTA address is in offsets 4 and 5 of the FILDES, so
RD is incremented by 4 before the 2 bytes in RF are copied into the FILDES.
Control is then transferred to fdminus5: (in getfddta:) to move RD back
to the beginning of the FILDES before returning.

-----------------------------------------------------------------------------

setfdeof:     Set EOF in file descriptor

  This function is used to set the EOF field in the FILDES pointed to by RD.
The EOF is at offset 6 and 7 in the FILDES so RD is incremented by 6 before
the 2 bytes in RF are copied into the FILDES.  A jump is then made to 
fdminus7: (in getfdeof:) to move RD back to the beginning of the FILDES
before returnign.

-----------------------------------------------------------------------------

setfdflgs:    Set flags in file descriptor

  This function sets the file flags in the FILDES pointed to by RD.  The
file flags are located at offset 8 in the FILDES, so RD is incremented by
8 before the value in D is written into the FILDES.  A jump to fdminus8:
(in getfdflgs:) to move RD back to the beginning of the FILDES before
returning.

-----------------------------------------------------------------------------

setfdofs:     Set offset in file descriptor

  This function will take the offset in R8:R7 and write it into the current
offset pointer in the FILDES pointed to by RD.  Since the current offset is
in the first 4 bytes of the FILDES, this function merely copies the bytes
from R8:R7 into the first 4 bytes of the FILDES.  Control is then transferred
to fdminus3: (in getfdofs:) in order to restore RD back to the beginning of
the FILDES before returning

-----------------------------------------------------------------------------

setfdsec:     Set current sector in file descriptor

  This function sets the current sector field of the FILDES pointed to by RD.
The current sector field is located at offset 15 of the FILDES, so RD is
first incremented by 15 and then the 4 bytes of R8:R7 are written into the
FILDES.  Control is then transferred to fdminus18: (in getfdsec:) to move
RD back to the beginning of the FILDES before returning.

-----------------------------------------------------------------------------

settrx:       Setup transfer address

  This routine is called by read: and write: in order to set R9 up as a
pointer into the files DTA at the correct offset based upon the current
file pointer in the FILDES.  Essentially what this is doing is taking the 
bottom 9 bits of the file pointer and adding it to the DTA address in 
memory.  The reason why 9 bits is significant is that a sector can hold
512 bytes of data, which takes 9 bits to address.

-----------------------------------------------------------------------------

setupfd:      Setup a new file descriptor

  This routine is called whenever a file is successfully opened or created.
This routine will setup the FILDES to hold the correct data for the open
file.

  first setfddrsc: is called to write the directory sector in R8:R7 into 
the FILDES in the directory sector field.  Then setfddrof: is called to
wrote R9 into the directory offset field of the FILDES.

  The current file pointer is set to zeros, or the beginning of the file by
setting R8:R7 to zero and then calling setfdofs:.

  Next the current sector needs to be set to invalid, this will prevent a
sector write when the files first sector is read.  This is done by setting
R8:R7 to 0ffffffffh and then calling setfdsec:.

  Next the the starting lump from the DIRENT pointed to by RF is read and
converted to a sector number by calling lumptosec:  lumptossec: returns 
with R8:R7 set to the first sector number of the starting lump of the file.
rawread: is the called in order to load the file's first sector into the 
DTA.

  Next the FILDES's flags are set to 0, indicating nothing has been written
and the file is read/write.  If the file was opened for readonly, when
control is returned to the open: routine, it will reset the flags to indicate
the readonly status of the file.

  Next the starting lump entry is read from the LAT table by calling
readlump:  It is then tested for 0FEFEh to see if the staring lump of the
file is also the last lump.  If it is, then bit 2 of the FILDES flags
will be set to indicate that the file pointer is in the final lump of the
file.  setfdflgs: will be called to write the flags to the FILDES.

  openeof: will then read the EOF value from the DIRENT and call setfdeof:
to set the EOF value into the FILDES.

  Control is then returned to the caller.

-----------------------------------------------------------------------------

startlump:    Get starting lump for a file

  This function is called whenever Elf/OS needs to know what lump numbers is
the first lump for the file of the specified FILDES.  The FILDES does not
contain the starting lump number for the file and therefore the directory
entry for the file needs to be read to get the starting lump number.

  Consumed registers are saved before RD is incremented by 9 to point to the
directory sector field of the FILDES.  The sector number is then copied into
R8:R7 and RD is set to point to the system FILDES.  rawread: is then called
in order to load the specified directory sector into the system DTA.

  RD is then restored back to the callers FILDES and incremented so that it
is pointing at the last byte of the directory offset at offset 0Eh.  The
value at this location in the FILDES is then addeded to the address of the
system DTA in order to determine where in the DTA the DIRENT for this
FILDES is located.  The addition starts with the low byte and then RD is
decremented so that the high byte can be computed.  After the addtions, R7
will point to the memory address in the system DTA where the DIRENT is 
located.

  R7 is incremented by 2 in order to read the least significan 16 bits of the
DIRENT's starting lump number.  In type 1 filesystems only the least 16
bits are used for the lump number.  The lump number is then copied from the
DIRENT into RA.

  Consumed registers are then recovered and RD is moved back to the beginning
of the caller's FILDES before control is returned to the caller.

-----------------------------------------------------------------------------

validate:     Check filename to make sure it is valid

  This function is called by several Elf/OS routines in order to validate
that the filename passed in through the API conforms to valid filenames.

  First validate: will check to see if the name is zero length, if so it
will return in error, DF set.

  valid_lp: will loop over each character of the filename and check to make
sure it is in the following set of characters: A-Za-a0-9.-_/.  If any
character is encountered besides these, then control is transferred back to
the caller with DF set to indicate an error.  RC maintains a count of 
characters checked, and by the end of the valid_lp: loop will contain the
number of characters in the filename.

  The count is compared to 19 to see if the filename is too long.  If the 
name is too long then again control is transfered back to the caller with
DF set to indicate an error.

  If all checks pass then DF will be cleared to indicate that the filename
was valid.

  Consumed registers are then restored and control is passed back to the
caller.

-----------------------------------------------------------------------------

warmboot:     Warmboot entry point
 
  This routine is the destination of the o_warmboot API call and is also
executed following the coldboot: procedure.

  The only thing warmboot: needs to do is reset the stack to the Elf/OS
stack frame.  At the point of the main command loop, there is nothing on
the stack and therefore if a program returns to Elf/OS by jumping to the
o_warmboot entry, then all Elf/OS needs to do is reset the stack.  If a 
user program does not maintain the stack, then it can make a jump to this
point to reenter the Elf/OS command loop without altering the current 
working directory.

-----------------------------------------------------------------------------

write:        Write bytes to file

  This function is the destination of the o_write API call and is used to
write bytes to an open FILDES.

  write: starts by saving the registers that it consumes and then sets RA
to RD + 8, this will set RA to the flags field of the FILDES.  The flags
will be querried to see if bit 1 is set.  If this bit is set then this file
was opened read only and writes are not allowed.  If the file is read only
then control is transfered to writeex: to cleanup and return to the caller.

  next settrx: is called in order to setup the registers for byte transfers
from the DTA to the user's specified buffer.  RB which will be the write
count is also set to zero.

  writelp: is the main write loop.  It will first check RC to see if there
are any more bytes to write.  If RC is zero, then all the request bytes
have been written and control passes down, otherwise control will be 
transferred to write1:.  When all the bytes are written the count in RB
will be copied into RC before control falls through to the writeex: routine.

  write1: starts by getting the flags byte of the FILDES, still being 
pointed to by RA and sets bits 0 and 4 to indicate that both the current
sector and this file have been written to.

  Next a byte is transferred from the users buffer being pointed to by RF
into the DTA being pointed to by R9.  both of these pointers are then
incremented and the bytes written counter, RB, is incremented.

  Next checkeof: is called to see if the file's EOF byte was written to.
If EOF has not been crossed then control will be transferred to write2:
otherwise RA is moved down to the EOF field in the FILDES and the EOF
is incremented by 1.  The EOF is then checked to see if the lump boundary
had been crossed.  If a lump boundary was crossed then append: will be called
to add another lump onto the end of this file.  Control then falls through
to write2:

  write2: starts by calling incofs: which will increment the current file
pointer in the first 4 bytes of the FILDES.  incofs: also checks to see if
sector or lump boundaries are crossed and loads the next sector of the file
if a boundary is crossed.  If incofs: returns with DF clear, meaning a new
sector was not loaded, then control is transferred back to writelp: to
process the next byte.  Otherwise settrx: is called to resetup the DTA
registers and then control moves back to writelp: for the next byte.

  writeex: gains control when no more bytes need to be written.  writeex:
restores all the consumed registers and then returns to the caller.

-----------------------------------------------------------------------------

writelump:    Write a value to a lat entry

  This routine is called in order to write an entry to the LAT table.  The
LAT table begins at sector 17 and for type 1 filesystems contains 256 LAT
entries.

  First a check is made of the requested lump value to determine if it is
lump 0.  Lump 0 is not allowed to be deallocated are changed since this is
the lump that contains the SDS.  If this lump is allocated to another file
and then the lump is written to, the Elf/OS disk will no longer be usable.
If the request lump is lump 0 then control is transferred immediately back
to the caller.

  Consumed registers are then saved and lmpsecofs: is called in order to
convert the lump number to a sector/offset.

  RD is set to point to sysfildes, the system FILDES, and rawread: is
called to load the needed LAT sector into the system DTA.

  The address of the system dta is added to the sector offset in R9 and
stored into RA for access.  This addition will make RA point to the physical
memory address where the lump entry is in the system DTA.

  The passed value in RF is then written into the LAT entry and rawwrite:
is then called to write the LAT sector back to disk.

  Consumed registers are then restored back to their original values and
control is returned to the caller.

-----------------------------------------------------------------------------

writesys:     Write a sectur using system fildes

  This routine is used by Elf/OS whenever it needs to write system related
sectors.  The system DTA is located at 100h and sysfildes is the FILDES that
is used whenever Elf/OS wants to use the system DTA.  Unlike normal FILDES's
sysfildes does not really describe an actual file, but is used to track which
sector is loaded into the system DTA and whether or not it has been modified.
This FILDES is needed because the rawwrite: and rawread: functions work off
of values in a FILDES.

  First RD is saved so that it can be reset with the address of sysfildes.
rawwrite: is then called to write the reqested sector to disk. After the 
sector has been written the original RD is restored and control is transferred
back to the caller.

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

Summary of Elf/OS subroutines:
------------------------------
append:       Append a lump to end of current file
chdir:        Change/view current directory
checkeof:     Check if file is at end
checkwrt:     Check to see if a sector needs to be written
cklstlmp:     Check for last lump and EOF
close:        Close a file
cmdlp:        Main command loop
coldboot:     Coldboot routine
create:       Create a new file
delchain:     Delete a chain of lumps
delete:       Delete a file
exec:         Execute a program
execbin:      Execute a file from /bin
finalsl:      Make sure a name has a final slash
finddir:      Find a directory
findsep:      Split pathname at separator
follow:       Follow a directory tree
freedir:      Get a free directory entry
freelump:     Find a free lump
getfddrof:    Get dir offset from file descriptor
getfddrsc:    Get dir sector from file descriptor
getfddta:     Get DTA from file descriptor
getfdeof:     Get EOF from file descriptor
getfdflgs:    Get flags from file descriptor
getfdofs:     Get offset from file descriptor
getfdsec:     Get current sector from file descriptor
getsecofs:    Get current sector/offset
gettmdt:      Get time and date from BIOS
incofs:       Increment current offset in fildes
lmpsecofs:    Convert lump number to latSector/latOffset
lmpsize:      Set shift count variable for current lump sector size
loadsec:      Load current sector from fildes
lumptosec:    Convert lump number to first sector number in lump
mkdir:        Make a directory
open:         Open a file
opendir:      Open a directory
openmd:       Open master directory
rawread:      Read a sector from disk
rawwrite:     Write a sector to disk
read:         Read bytes from file
readlump:     Read a value from a lat entry
readsys:      Read a sector using system fildes
rename:       Rename a file
rmdir:        Remove a directory
searchdir:    Search a directory for an entry
secloaded:    Determine if needed sector is already loaded
secofslmp:    Convert latSector/latOffset to lump number
sectolump:    Convert sector number to lump number
sector0:      Load sector 0
seek:         Perform file seek
seekend:      Seek fildes to end
setfddrof:    Set dir offset in file descriptor
setfddrsc:    Set dir sector in file descriptor
setfddta:     Set DTA in file descriptor
setfdeof:     Set EOF in file descriptor
setfdflgs:    Set flags in file descriptor
setfdofs:     Set offset in file descriptor
setfdsec:     Set current sector in file descriptor
settrx:       Setup transfer address
setupfd:      Setup a new file descriptor
startlump:    Get starting lump for a file
validate:     Check filename to make sure it is valid
warmboot:     Warmboot entry point
write:        Write bytes to file
writelump:    Write a value to a lat entry
writesys:     Write a sectur using system fildes



Package Format:
---------------

  Elf/OS programs are normally packaged in Elf/OS package format.  This
format is read by the INSTALL tool to load new packages onto the Elf/OS
filesystem.  

  The beginning of a package image contains a table that specifies what
is in the package and where it is located.  The table has the following
format:

n bytes   - The name of the package as an ASCIIZ string.
2 bytes   - Offset into the package where the file is found
2 bytes   - Ending offset
2 bytes   - file load address (this and following 4 bytes are the executable
            header)
2 bytes   - Number of bytes to load
2 bytes   - Execution address

  The next entry in the table would then follow, or a 00 byte to indicate
that there are no more entries.

  Following the table is the actual file data referenced in the table.

  Most packages created by Mike Riley were intended to be loaded from ROM
on a Micro/Elf or Pico/Elf.  These roms have the package table at 8000h and
the file data following.


Elf/OS Install Package:
-----------------------

  The Elf/OS install package is mostly in Package format.  In the standard
distribution the package table will be at 8000h and the Elf/OS installer
application will be located at 9000h.  Other Elf/OS install distributions
exist (for example for the Elf 2000) which are in a different format.

  The Install application is made up of 4 tools: HDINIT, FSGEN, SYS, and
BININST.  Each of the steps 1 through 4 on the installer menu runs one of
these tools.

HDINIT (step 1):

  The main purpose of HDINIT is to determine how many sectors the disk
device contains.  It operates in 2 modes, Quick and Full.  In Quick
mode HDINIT will read the device identity from the IDE device and extract
the sector count.  In Full mode, HDINIT will initialize all sectors to 00
and when it gets a write error will stop and use the last successfull 
sector number as the number of sectors.  While HDINIT is running in Full
mode it will update the screen display every 256 sectors initialized.  
Although internally HDINIT uses 32 bit sector numbers, the display only
shows the bottom 16 bits of the count, so it is possible to see this
number wrap around and start counting up again from zero.

  Once the sector count has been determined the count will be written to
the SDS (sector 0) at offset 100h-103h.

FSGEN (step 2):

  FSGEN reads the sector count set by HDINIT and determines how many lumps
are contained on the disk.  Based upon the number of lumps it creates the
LAT table with the required number of entries to map the disk.  The sectors
occupied by the SDS, KIB, and LAT are marked in the LAT as unallocatable.
Sectors beyond the end of disk that exist in the LAT table are also marked
as unallocatable.

  FSGEN will place the Master Directory in the first available lump in the
Common Data Area following the LAT table, and create the MD DIRENT in the
SDS as well as the rest of the data stored at offset 100h and up in the SDS.

  FSGEN also writes the Elf/OS boot loader into the bottom 256 bytes of
sector 0.

  The currently shipping version of FSGEN will only create type 1 filesystems
with 8 sectors per lump.

SYS (step 3):

  SYS copies the kernel image from the install package into the Kernel
Image Block, sectors 1 through 16 of the disk.  After a system has been
setup and running, this option can be used to load new kernel images into
the KIB.

BININST (step 4):

  BININST is used to copy the rest of the Elf/OS utilities into the /BIN 
directory on the disk.  BININST works by copying the kernel image from
the install package into its load address in memory and then sets up
enough of it so that the filesystem API calls are available.  BININST
actually uses the Elf/OS kernel to write the files onto disk.

  BININST reads the package table at 8000h (standard distribution) and
queries the user for each entry in the table.  For each entry the user
says Yes to, will be copied to the disk using o_open, o_write, and o_close
of the kernel.


