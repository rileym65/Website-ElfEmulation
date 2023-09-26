                              ELF/OS V0.2.6
                               3/1/2005

Introduction:
-------------
  Thank you for your interest in Elf/OS.  Elf/OS is a disk based operating
system, or DOS, for Elf class computers.  It currently provides access to
IDE/CF drives up to 268mb in size.
  The Elf/OS system consists of two major subsystems. The first is the BIOS,
or Basic Input/Output Subsystem.  The BIOS provides a uniform interface to
Elf/OS irregardless of the underlying hardware.  The BIOS was designed to be
easily adaptable to various hardware platforms.  The current implementation
of the BIOS has been tested on the Micro/Elf and Elf II computers.  The
second major subsystem is the Elf/OS kernel.  The kernel provides resource
management of the hard drive.  The Kernel contains an API, Application
Programming Interface, that allows programs to create, read, and write disk
files.


Hardware Requirements:
----------------------
  The following hardware is required for running Elf/OS:

  * Micro/Elf, Elf II, Super Elf, PE Elf, or other 1802 based computer
  * Minimum of 8k of ram starting from 0000h
  * Ability to add 32k of rom starting from 8000h
  * Serial Interface, Q/EF?
  * Serial Terminal
  * IDE interface
  * IDE device


Installation:
-------------
  The installation package for Elf/OS comes in a 32k rom image that must
be burned into rom and attached to your computer.  The BIOS resides in rom
from F000h through FFFFh, the installation package for Elf/OS resides in rom
from 8000H through EFFFh.

1. Start your Elf computer with the Elf/OS install rom attached.

2. Using load mode, insert these bytes into low memory: C0 90 00
   This sets up a long branch to the Elf/OS installer.

3. Turn off load mode and start run mode.  At this point the computer will be
   waiting for you to press <ENTER> on your terminal in order to setup the 
   baud rate information.  After which you should see this menu on your
   terminal:

   Elf/Os Installation
   1> Run hard drive init tool
   2> Run filesystem gen tool
   3> Run sys tool
   4> Install binaries
   5> Boot Elf/OS

      Option ?

4. NOTE: This step need only be performed once for a given hard drive.
   Running this step erases any information stored on the drive.

   Run option 1 to initialize the hard drive.  Depending on the speed of your
   computer and the size of the hard drive this could take from several 
   minutes to several hours.

   During this step there will be a sector count on the screen.  Depending on
   the size of the drive, this number could wrap around to zero, this is 
   normal.  The OS uses 32 bit sector address, but the sector count during
   this step only shows the bottom 16 bits.

   When the init is complete you should see somethign similar to:

   Total Sectors: 53248
   Format Complete

   and the installation menu will again be presented.

5. NOTE: This step you also only need to run once.  This step generates the
   ELF/OS filesystem on the disk.  It will destroy any filesystem that is
   already present on the disk.

   Run option 2 to setup the Elf/OS filesystem.  This step should only take
   a couple of minutes.  You should get a mesage similar to:

  Total Sectors: 53248
  AU Size: 8
  Total AUs: 6656
  Master Dir Sector: 48
  Filesystem generation complete

  Then the installation menu will be presented again.

6. Run option 3 to copy the OS kernel onto the hard disk.  This step does not
   damage any data and therefore can be used to re-install the kernel or for
   installing new kernel versions.  At the conclusion of the command you 
   should see:

  System copied.

   and then the installation menu will be displayed again.

7.  Select option 4 to install the utilities that accompany Elf/OS.  Each
    utility will be shown and you will be given the option whether or not to
    install it.  Utilities not installed at this time can be installed at a
    later time by using the INSTALL utility (if you load it now)

    A description of each utility can be found later in this manual.

8.  At this point Elf/OS is installed.  You can now select option 5 to boot
    into Elf/OS.  From this point on, in order to boot elfos, from a cold
    boot of the computer would be to enter load mode and enter these bytes:
    C0 FF 00.  This sets up a long branch to the BIOS IDE boot program.

 
Post Installation:
------------------
  After booting Elf/OS for the first time, you can execute DIR and see all the
utilities installed during the installation process.  The installer currently
places all the utilities into the root directory.  It is actually more useful
to have the utiliites in a directory called BIN/.  When you specify a command
for Elf/OS to execute, Elf/OS first looks in the current directory for the
specified program, if it is not found then it will look in BIN/.

  First make the directory:

    MKDIR BIN

  Then copy the DIR program into it:

    COPY DIR BIN/DIR

  Then delete the copy in the root directory:

    DEL DIR

  Repeat the COPY and DEL commands for each of the other utilities you would
like in the BIN/ directory.


First steps in Elf/OS:
----------------------

  This is a quick tutorial to help you get started with Elf/Os.  Commands that
you should type will be towards the left, the output from the commands will
be indented.  Note also that the results of commands may differ from your
installation.

  When Elf/OS first boots you will get the Elf/OS Ready prompt.  In fact any
time Elf/OS is waiting for you to give it a command you will get the Elf/OS
Ready prompt.  Lets take a look at the root directory:

        Elf/OS Ready
DIR
        PROJECTS/
        FORTH/
        BASIC/
        BIN/

  Lets also take a look at what is in the BIN/ directory.  Any programs in the
BIN/ directory can be executed from anywhere.

DIR BIN/
        DIR
        CHDIR
        COPY
        EDIT
        RENAME
        VER
            (and probably many others)

  To get the version of Elf/OS, use the VER command:

VER
        0.2.1 Build 5 7/12/2004

  You can also use the VER command on the utilities:

VER BIN/DIR
        7/9/2004

  Lets make a directory to work in:

MKDIR TUTORIAL

  We will now change to the that direcotry:

CHDIR TUTORIAL/

  We can DIR the directory and see what is there.  Since we just made it, it
should be empty:
DIR
        (will be empty)

  CHDIR when used without a pathname will show you what the current directory
is:

CHDIR
        /TUTORIAL/

  Lets use the EDIT program and create a small assembly language program:

EDIT BAUD.ASM
        New file
        >

  The I command in edit allows us to add lines to the file:

I        ORG  2000H
ISTART:  GLO  RE
I        STR  R2
I        SEX  R2
I        OUT  4
I        DEC  R2
I        SEP  R5
I        END  START
S
Q
        Elf/OS Ready

  If we look at the directory now, we will see our new file:

DIR
        BAUD.ASM

  Using the TYPE command we can look at the contents of an ASCII file:

TYPE BAUD.ASM
                ORG  2000H
        START:  GHI  RE
                STR  R2
                SEX  R2
                OUT  4
                DEC  R2
                SEP  R5
                END  START

  Now lets assemble it and make an executable program.  If you get errors
in the output list, then you probably made a typing error when you created
the BAUD.ASM file.  Using the editor you can go back and fix it.

ASM BAUD
                ORG  2000H
        START:  GHI  RE
                STR  R2
                SEX  R2
                OUT  4
                DEC  R2
                SEP  R5
                END  START

  If we do a directory now, we will now see the file created by the
assembler:

DIR
        BAUD.ASM
        BAUD

  To view the contents of a binary file, you can use HEXDUMP:

HEXDUMP BAUD
        :0000 20 00 20 05 20 00 9E 52 E2 64 22 D5

  If you are familiar with 1802 opcodes, you will notice there are more
bytes here than the original assembly program had.  The assembler adds a 6
byte header to the file.  This header is called the execution header and tells
Elf/OS where the program is to be loaded and where the exec address is.

  We can now run the program.  It will not output anything to the terminal,
but will output the baud constant to the data displays of your elf.

BAUD
        (will output baud rate constant to data displays)

  Lets go ahead now and delete the executable BAUD program

DEL BAUD

  Performaing a directory will confirm the deletion of the file:

DIR
        BAUD.ASM

  The MINIMON utility can be used to view or modify memory:

MINIMON
        >

  The ? command allows you to view memory:

?3000
        3000: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
        3010: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
        (more lines after these)

  The ! command allows us to write bytes into memory

!3000 7A 7B 30 00

  Lets look at what we wrote:

?3000
        3000: 7A 7B 30 00 00 00 00 00 00 00 00 00 00 00 00 00
        3010: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
        (more lines after these)

  The / command will return us to Elf/OS
/
        Elf/OS Ready

  You can use the SAVE command to write a program in memory to disk:

SAVE
        File dump utility
        Start address:
3000
        End address:
3004
        Exec address:
3000
        Filename:
BLINK
        Elf/OS Ready

  Performing a directory now will show the SAVEd file.
DIR
        BAUD.ASM
        BLINK

  You can also do a HEXUMP of it.  Again notice that the SAVE command added
the 6 byte execution header:

HEXDUMP BLINK
        :0000 30 00 00 05 30 00 7A 7B 30 00 00

  The COPY command can be used to copy one file to another:

COPY BLINK LED

  The DIR command will confirm the new file:

DIR
        BAUD.ASM
        BLINK
        LED

  Now delete the BLINK program:

DEL BLINK

  And again DIR will show you what has happened:

DIR
        BAUD.ASM
        LED

  You can use the RENAME command to change the name of a file:

RENAME LED BLINK

DIR
        BAUD.ASM
        BLINK

  The CHDIR command with just a / will return us to the root directory:

CHDIR /

  Here we are back at the root.  notice the new TUTORIAL/ directory:

DIR
        PROJECTS/
        FORTH/
        BASIC/
        BIN/
        TUTORIAL/

  To find out how much space is left on your disk, you can use the FREE
command:

FREE
        Total AUs: 6656
        Free AUs : 6598

  This should be enough to get you started.  For more detailed information
about Elf/OS commands or the Elf/OS API, refer to the reference section.


Filenames:
----------
  Filenames may consist of any character except / (/ is the directory
separator).  Filenames can consist of up to 19 characters.  Elf/OS does not
use the concept of extensions, therefore they are not necessary, but you can
still use them if you desire in order to distinguish file types.

Directories:
------------
  Elf/OS supports a nested directory filesystem.  There is currently a limit
of 80 characters tho for a pathname, therefore you should not nest too deeply.

  When using MKDIR to create directories, a final / must NOT be appended to
the directory name.

  Otherwise when specifying directories, you must append a final /

Examples:

  MKDIR BIN        - Create directory BIN
  DIR BIN/         - Show contents of directory BIN
  CHDIR BIN/       - Change directory to BIN
  CHDIR /          - Change directory to the root direcotory

  When specifying pathnames, if there is a leading /, then the pathname is
relative to the root directory.  If there is no leading /, then the pathname
is relative to the directory you are currently in.


Command Reference:
------------------

CHDIR              Change/View current directory

Usage: CHDIR       - Show current directory
       CHDIR path  - Change current directory to specified path

--------------------------------------------------------------------------


COPY               Copy a file

Usage: COPY src dest
       src         - filename of file to copy
       dest        - destination pathname

--------------------------------------------------------------------------

DEL                Delete a file

Usage: DEL pathname
       pathname    - pathname of file to delete

--------------------------------------------------------------------------

DIR                Show disk directory

Usage: DIR         - Show current directory
       DIR path    - Show directory of specified path
           path    - Path of directory to display

--------------------------------------------------------------------------

DUMP               Dump memory contents to a disk file

Usage: DUMP

Notes: DUMP will prompt for the starting address, the ending address, and
       the name of the file to dump to

--------------------------------------------------------------------------

EDIT               Edit an ASCII file

Usage: EDIT file
         file      - File to edit.  The file will be create if it does not
                     exist.

Notes: Once edit is running you will get an '>' prompt.  The following 
       commands are available.

          B       - Move to bottom of buffer
          D       - Move down one line
        ,nD       - Move down n lines
          Itext   - Insert text at current location
         nItext   - Move to line n, then insert text
          I       - Insert text until <CTRL><C> pressed
         nI       - Insert text at line n until <CTRL><C> pressed
         nG       - Make line n the current line
          K       - Kill (delete) the current line
         nK       - Move to line n, and then delete line
        ,nK       - Kill n lines starting from current line
       n,mK       - Kill m lines starting from line n, n becomes current
          P       - Print the current line
         nP       - Print line n
        ,nP       - Print n lines starting from current line
       n,mP       - Print m lines starting from line n
          Q       - Quit to Elf/OS
          S       - Save buffer to file specified when edit was started
          T       - Move to top line of buffer
          U       - Move up one line
        ,nU       - Move up n lines

--------------------------------------------------------------------------

EXEC               Execute program already in memory

Usage: EXEC addr
         addr      - Address to begin execution at

--------------------------------------------------------------------------

FREE               Show disk usage

Usage: FREE

Notes: This program will show the total number of AUs per disk as well as
       how many AUs are currently free.

--------------------------------------------------------------------------

HEXDUMP            Show contents of a file in hex format

Usage: HEXDUMP file
         file      - File to show the contents of

--------------------------------------------------------------------------

INSTALL            Pachage installer

Usage: INSTALL

Notes: This program is similar to option 4 of the Elf/OS installer.  It
       reads an install package header located at 8000h in memory and asks
       to install each program found in the header.

--------------------------------------------------------------------------

LOAD               Load executable file into memory without executing

Usage: LOAD file
         file      - file to load into memory

Notes: After loading the file, LOAD will display the start address and exec
       address for the program.

--------------------------------------------------------------------------

MINIMON            Mini monitor for changing/viewing memory

Usage: MINIMON

Notes: After minimon is loaded you will get a '>' prompt.  The following 
       commands are available:

         ?addr               - Display memory starting at specified address
         !addr byte byte ... - Store bytes into memory
         =src dst len        - Copy len bytes from src to dst
         @addr               - Execute at specified address
         /                   - Return to Elf/OS

--------------------------------------------------------------------------

MKDIR              Make a directory

Usage: MKDIR path

--------------------------------------------------------------------------

PATCH              Applies program patches

Usage: PATCH file
         file      - Patch control file

Notes: The patch control file is fomatted as follows:
         Line 1     - Filename of file to be patched
         Line 2     - Either R for relative mode, or first data line
         Line 3 ... - Remaining data lines.

       Data lines are formatted as first 4 hex digits, address to start
       patching, followed by a list of 2 hex digits for the bytes to 
       write at specified address

       Relative mode first reads the files execution header to determine
       file offsets.  The addresses used in the data lines are the memory
       addresses instead of the file offset.

--------------------------------------------------------------------------

RENAME             Rename a file

Usage: RENAME old new
         old       - Old filename
         new       - New filename

Notes: RENAME cannot be used to move a file from one directory to another,
       you must use the COPY command.

--------------------------------------------------------------------------

RMDIR              Remove a directory

Usage: RMDIR path
  
--------------------------------------------------------------------------

SAVE               Save memory contents to executable file

Usage: SAVE

Notes: Save will prompt for the starting address in memory, the ending
       address in memory, the execution address, and the filename to save to.

--------------------------------------------------------------------------

STAT               View file statistics

Usage: STAT filename

Notes: Currently shows size of file

--------------------------------------------------------------------------

TYPE               Show contents of an ASCII file

Usage: TYPE file
         file      - Filename to type.

--------------------------------------------------------------------------


API Reference:
--------------
0306h  O_OPEN    - Open file
       Args:  RF = Pointer to pathname
              RD = Pointer to file descriptor, DTA must be pre-filled
              R7 = Flags
                   1  Create if file does not exist
                   2  Truncate file on open
                   4  Open for append (moves pointer to eof)
       Returns:  DF=0 - Success
                 RD - File descriptor
                 DF=1 - Error
                    D - Error Code

0312h  O_CLOSE   - Close file
       Args:  RD = File descriptor
       Returns:  DF=0 - Success
                 DF=1 - Error
                    D - Error Code

030Ch  O_WRITE   - Write to file
       Args:  RD = File descriptor
              RF = Pointer to bytes to write
              RC = Count of bytes to write
       Returns:  RC = Count of bytes written
                 DF=0 - Success
                 DF=1 - Error
                    D - Error Code

0309h  O_READ    - Read from file
       Args:  RD = File descriptor
              RF = Pointer to buffer
              RC = Count of bytes to read
       Returns:  RC = Count of bytes read
                 DF=0 - Success
                 DF=1 - Error    
                    D - Error Code

030Fh  O_SEEK    - Change file position
       Args:  R8 = High word of seek address
              R7 = Low word of seek address
              RD = File descriptor
              RC = Seek from:
                   0  Beginning of file
                   1  From current position
                   2  From end of file
       Returns:  R8 = High word of current file pointer
                 R7 = Low word of current file pointer
                 DF=0 - Success
                 DF=1 - Error
                    D - Error Code

031Bh  O_RENAME  - Rename a file
       Args:  RF = Source filename
              RC = Destination filename
       Returns:  DF=0 - Success
                 DF=1 - Error
                    D - Error Code

0318h  O_DELETE  - Delete a file
       Args:  RF = Filename
       Returns:  DF=0 - Success
                 DF=1 - Error
                    D - Error Code

031Eh  O_EXEC    - Execute a program
       Args:  RF = Command line
       Returns:  DF=0 - Success
                 DF=1 - Error
                    D - Error Code

0315h  O_OPENDIR - Open directory for reading
       Args:  RF = Pathname
       Returns:  RD - File descriptor
                 DF=0 - Success
                 DF=1 - Error
                    D - Error Code

0321h  O_MKDIR   - Make directory
       Args:  RF = Pathname
       Returns:  DF=0 - Success
                 DF=1 - Error
                    D - Error Code

0324h  O_CHDIR   - Change/Show current directory
       Args:  RF = Pathname or buffer to place current path
       Returns:  DF=0 - Success
                 DF=1 - Error
                    D - Error Code

0327h  O_RMDIR   - Remove directory (must be empty)
       Args:  RF = Pathname
       Returns:  DF=0 - Success
                 DF=1 - Error
                    D - Error Code

032Ah  O_RDLUMP  - Read value from LAT table
       Args:  RA = lump number
       Returns: RA - value of lump

032Dh  O_WRLUMP  - Write lump value into LAT table
       Args:  RA - lump to write
              RF - value to write
       Returns: None

0330h  O_TYPE - Type character to terminal
       Args: D - Character to type
             RE.1 - Baud constant
       Returns: None

0333h  O_MSG - Type message to terminal
       Args: RF - pointer to ASCIIZ message
             RE.1 - Baud constant
       Returns: None

0336h  O_READKEY - Read character from terminal
       Args: RE.1 - Baud constant
       Returns: D - Read character

0339h  O_INPUT - Input string from terminal
       Args: RF - Pointer to buffer
             RE.1 - Baud constant
       Returns: DF=0 - Input finished with <ENTER>
                DF=1 - Input finished with <CTRL><C>

033Ch  O_PRTSTAT - Get printer status
       Args: None
       Returns: D - printer status byte

033Fh  O_PRINT - Print character on printer
       Args: D - Character to print
       Returns: None

File Descriptor Format:
-----------------------
0-3   - Current Offset
4-5   - DTA
6-7   - EOF byte
8     - Flags
        1 - sector has been written to
        2 - file is read only
        4 - currently have last sector
        8 - descriptor not in use
       16 - file has been written to
      128 - file is on slave drive
9-12  - Dir Sector
13-14   - Dir Offset
15-18 - Current Sector

Hard Disk Structure: (LBA mode)
-------------------------------
Sector 0            Boot Sector
Sector 1-16         OS Kernel Image
Sector 17-..AS      Allocation table
Sector AS+1         Master Directory
Sector AS+2 - end   Data Sectors

OS boot code is in first 256 bytes of sector 0
Sector 0 contains disk information:
256-259  - Total Sectors
260      - Filesystem type
261-262  - Master Directory pointer
263-264  - Reserved
265-266  - Allocation unit size (in sectors)
267-270  - Number of allocation units
300-331  - Master dir direntry

Directory Structure:
--------------------
byte   description
0-3    First Lump, 0=free entry
4-5    eof byte
6      flags1
       0 - file is a subdir
7-8    Date (see coding below)
9-10   Time (see coding below)
11-31  filename

Date format:              Time Format:
------------              ------------
7654 3210  7654 3210      7654 3210  7654 3210
|_______|____|_____|      |____||______||____|
  YEAR    MO     DY         HR    MIN    SEC/2



