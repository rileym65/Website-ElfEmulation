                                Rc/Basic
                                   by
                            Michael H. Riley

  Rc/Basic is a BASIC interpreter written for use on 1802 based computers.
There are 2 major variants of the language, L1 and L2.  L2 is an extension of
the L1 interpreter and will run programs written for L1.  Rc/Basic exists also
in two form factors, ROM and Elf/OS.  All versions of Rc/Basic as well as the
source code can be obtained from www.elf-emulation.com.

Introduction:
-------------
  BASIC is an acronym for Beginners All-purpose Symbolic Instruction Code.
BASIC was developed in the early 70s in order to provide an easy means for
writing software for people new to computers, hence Beginners in the name.
BASIC is a very easy language to learn and is capable of perfomring a wide
range of tasks, hence All-purpose.  Early computers were programmed in codes
that were difficult to use and required a lot of forthought on the part of
the programmer on how data and program code is stored in memory.  This made
early programs difficult to write and very difficult to modify.

  Higher level languages were developed in order to abstract away the 
specifics on how the computers actually worked and making it easier for
programmers to write and maintain their software.  There are two basic types
of higher level languages, compilers and interpreters.  A compiler takes the
program that the developer wrote and translates it into the machine code that
the computer understands.  Interpreters typically use intermediate code 
rather than direct machine lanugage.  A line of a program is tokenized or 
converted to the intermediate code and then the interpreter looks at the
codes and executes subroutines in the interpreter to handle each token.

  Rc/Basic is an interpreted language.  It accepts input from the user and
either immediately executes the command or stores it in memory for later
execution.  The advantage of an interpreter is that it allows you to quickly
see what your commands will do.  With a compiler you would have the steps of
converting your code into machine language before you could see the results
of your commands.

Direct Mode:
------------
  BASIC has two modes of operation: direct and stored program.  In direct
mode BASIC will attempt to execute what you type immedately:

PRINT "HELLO WORLD"
  HELLO WORLD

  Direct mode can also be used for doing calculations, in other words, it can
be used as an elaborate calculator.  Here are some examples:

PRINT 5*4
    20

A=10
B=20
PRINT A*B
    200

  In direct mode you can use variables in addition to numbers.  It is
important to know however that any values stored in variables will be cleared
whenever a program is RUN.

Program Mode:
-------------
  In stored program mode lines that are entered are not immediately executed,
but are stored into program memory as part of a whole program.  To store a 
line into memory you just add a line number in front of the command:

10 PRINT"HELLO"

  This line would then be added to the stored program.  The numbers in front
of the command specify where in the program this line should be inserted.
The lower the number is, the more towards the beginning of the program.  So
for instance, line 10 will be executed before line 20.

  If a line already exists with the same line number then it will be 
overwritten:

10 PRINT "HELLO"
LIST
  10 PRINT "HELLO"
10 PRINT "BYE"
LIST
  10 PRINT "BYE"

  This is how your programs are edited.  If you have a mistake in a line, all
you have to do is type the line again and it will be replaced.

  If you specify a line number without any command, then that line will be
delete from the program:

10 PRINT"HELLO"
20 PRINT"BYE"
LIST
  10 PRINT "HELLO"
  20 PRINT "BYE"
10
LIST
  20 PRINT "BYE"

  As in the example above it is customary not to number each line right
after another, but rather to leave space between the line numbers.  This way
if you need to insert something between two lines of your program there will
still be line numbers available for the new line.

Numbers:
--------
  Rc/Basic uses 16-bit integers for numeric computation.  The range of numbers
allowed is from -32768 through +32767.  When numbers are used in expressions,
if there is no leading - sign the number is considered positive.  A + sign is
not needed before positive numbers.

Variables:
----------
  Variables allow for storage of values.  Variables are handled differently
between the L1 and L2 interpreters.

  In L1 the only supported variables are integer variables and have the auto-
matic names of A through Z.

  L2 allows two types of variables, integers and strings.  L2 variable names
allow for multiple character names which must start with A through Z and then
can use A through Z as well as 0-9.  Variable names are limited in length to 
248 characters, but for performance reasons should be kept to shorter lengths.

  String variables must have a $ appended to the variable name, for example A$.
String variables can hold strings of characters of up to any length up to the
maximum available memory.  The length of string variables does not need to be
allocated before use, they are dynamically created on the heap.

Expressions:
------------
  In nearly all places where numbers are expected you can use arithmatic
expressions in place of the numbers, even in the destinations of GOTO and
GOSUB.
The following operators are valid in expressions:
  * = multiplication
  / = Division
  + = Addition
  - = Subtraction
AND = Logical AND
 OR = Logical OR
  & = Same as AND
  | = Same as OR

Relational operators may also be used in expressions.  When a relational
operator evalutes true its result is -1 otherwise it results in 0.  The
following relational operators are available:
  = - Equality
 <> - Inequality
  < - Less than
  > - Greater than
 <= - Less than or equal
 >= - Greater than or equal

Order of Precedence:
--------------------
Expressions are evaluated with a given precedence to the operators.  For
operators that are found at the same precedence level, they processed from
left to right.  Rc/Basic follows the standard convention for operator
precedence:

1. Functions and variable references
2. * /
3. + -
4. AND OR & |
5. = <> < > <= >=

Prececence can be altered by the use of parentheses.

Expression Examples:
--------------------
Expression                              Result
----------------------------------------------
2*5+3                                       13
2*(5+3)                                     16
5 OR 2                                       7
5 AND 3                                      1
5 * (3 < 4)                                 -5
5 * (3 = 4)                                  0
(3 < 4) AND (5 < 6)                         -1

In addition to numbers and variable references the following functions can
also be utilized in expressions:
  ASC, FLG, FRE, INP, LEN, PEEK, RND, USR, VAL, VARPTR

String Expressions:
-------------------
  The only valid operator for string expressions is the concatenation operator
which is the + symbol.  The concatenation operator will create a new string
that consists of both strings that are arguments of the concatenation.

Example:

10 A$="ABC"
20 B$="DEF"
30 C$=A$+B$
40 PRINT C$

RUN
    ABCDEF

  In addition to the concatenation operater there are the following string
functions which can be used in string expressions:
  CHR$, LEFT$, MID$, RIGHT$, STR$

Example:

10 A$="ABCDEF"
20 B$="XYZ"
30 C$=LEFT$(A$,3)+B$
40 PRINT C$

RUN
    ABCXYZ


Multi-Statement Lines:
----------------------
  Rc/Basic allows you to put multiple command on the same line.  Each command
needs to be separated by the : character.  For example:

10 FOR I=1 TO 10:PRINT I:NEXT I

  The limit of each line is 252 characters.


-------------------------------------------------------------------------------

Function Reference:
-------------------
-------------------------------------------------------------------------------
ASC(sexpr)                                                 L2 Only

  This function will return the ASCII value for the first character in the
specified string expression.

Examples:

PRINT ASC("ABC")
    65

PRINT ASC("1")
    49

-------------------------------------------------------------------------------
CHR$(expr)                                                 L2 Only

  This function takes the expression and produces a 1 character string that
is the ASCII character for the specified expression.

Example:

10 A$=CHR$(65)
20 PRINT A$

RUN
    A

-------------------------------------------------------------------------------
FLG()

  This function will read the 1802's EF lines and produce a merged result of
all 4 lines.  The result is defined as follows:
 
  EF1 = 1
  EF2 = 2
  EF3 = 4
  EF4 = 8

  If EF1 and EF3 were active then FLG() would return 5.

-------------------------------------------------------------------------------
FRE()

  This FRE function allows you to determine how much memory is left.  To be
more precise, it returns the memory that is above program/variable space and
below the stack/heap space.

Example:
  
PRINT FRE()
    16274

-------------------------------------------------------------------------------
INP(port)

  This function will read the specified input port and return the result.  port
may be from 1 to 7.

-------------------------------------------------------------------------------
LEFT$(sexpr,expr)                                          L2 Only

  This function will return the specified number of characters on the left
side of the specified string expression.

Example:

PRINT LEFT$("ABCDEFG",3)
   ABC

-------------------------------------------------------------------------------
LEN(sexpr)                                                 L2 Only

  This function will return the length of the given string expression.

Example:

PRINT LEN("ABCD")
    4

-------------------------------------------------------------------------------
MID$(sexrp,start,len)                                      L2 Only
  This function will extract the middle protion of a string expression.  The
resulting string will start at the specified position and be the specified 
length.

Example:

PRINT MID$("ABCDEFG",2,3)
    BCD

-------------------------------------------------------------------------------
PEEK(address)

  The PEEK function allows the program to retrieve a 1 byte value from memory.

-------------------------------------------------------------------------------
RIGHT$(sexpr,expr)                                         L2 Only

  This function will return the specified number of characters on the right
side of the specified string expression.

Example:

PRINT RIGHT$("ABCDEFG",3)
   EFG

-------------------------------------------------------------------------------
RND(range)

  The RND function will generate a random number from 0 to 1 less than the
specified range.  For example if RND(6) were issued, it would return a random
number from 0 to 5.

-------------------------------------------------------------------------------
STR$(expr)                                                 L2 Only

  This function will produce a string representation of a numeric expression.
This function is used to convert numbers to strings.

Example:

10 A$=STR$(5*100)
20 PRINT A$

RUN
   500

-------------------------------------------------------------------------------
USR(address)
USR(address,expr)

  The USR function is used to call a Machine Language subroutine.  The address
argument is required in both versions and specifies the address of the ML
routine to be executed.  If the second argument is provided, this value will
be loaded into RF prior to the ML routine being called.  The return value of
this function is the value in RF when the ML routine returns.

  See the section on Machine Language Subroutines for more information on 
using this function.

-------------------------------------------------------------------------------
VAL(sexpr)                                                 L2 Only

  This function will return an integer equivalent for the specified string
expression.  This is the function used to convert a string representation
of an integer to binary integer format.

Example:

10 A$="123"
20 I=VAL(A$)
30 PRINT I

RUN
   123

-------------------------------------------------------------------------------
VARPTR(varname)                                            L2 Only

  This function returns the address of the data field for the specified 
variable.  See the Advanced Techniques section for more on how to use this
function.

-------------------------------------------------------------------------------


Program Statements:
-------------------

-------------------------------------------------------------------------------
CLEAR                                                      L2 Only

  The CLEAR statement will remove all variables, variable values, strings,
string values and arrays from the heap.  Essentially the CLEAR command will
leave memory in the same state as if RUN had just been executed.

Example:

10 A=5
20 PRINT A
30 CLEAR
40 PRINT A

RUN
   5
   0

-------------------------------------------------------------------------------
DATA value,value,value,...                                 L2 Only

  The data command provdes a means to store data values inside your program.
These values can then be read using the READ command.  The current version
of L2 only allows for integer values in DATA statements.

  See READ for examples and further information on DATA.

-------------------------------------------------------------------------------
DIM var(dim[,dim,...]),...                                 L2 Only

  The DIM statement allows you to create integer arrays.  Multi-dimensional
array are allowed.  Each dim argument specifies the largest valid index for
the specified array and axis.

  A dimensioned variable is considered a distinct entity from its name, 
therefore A and A() do NOT refer to the same entity.  As such you can use the
same name for both simple variables as well as arrays.

Examples:

10 DIM A(5)
20 FOR A=0 TO 5:A(A)=A*2:NEXT
30 FOR I=0 TO 5:PRINT A(I);" ";:NEXT

RUN
   0 2 4 6 8 10

10 DIM A(10,10)
20 FOR Y=1 TO 10:FOR X=1 TO 10:A(X,Y)=X*Y:NEXT:NEXT
30 FOR Y=1 TO 10:FOR X=1 TO 10
40 IF A(X,Y)<10 PRINT"   ";
50 IF A(X,Y)>9 IF A(X,Y)<100 PRINT"  ";
60 IF A(X,Y)=100 PRINT" ";
70 PRINT A(X,Y);
80 NEXT:PRINT:PRINT

RUN
     1   2   3   4   5   6   7   8   9  10
     2   4   6   8  10  12  14  16  18  20
     3   6   9  12  15  18  21  24  27  30
     4   8  12  16  20  24  28  32  36  40
    ...
    10  20  30  40  50  60  70  80  90 100

-------------------------------------------------------------------------------
END
 
  This statement will cause the program to terminate.

-------------------------------------------------------------------------------
FOR var=start TO end [STEP expr]                           L2 Only
  NEXT [var]

  The FOR statement allows you to build controlled loops into your programs.
FOR requires a variable to store the current loop value in as well as the 
start and ending values for the loop.  The loop will end when the value in
the loop variable exceeds the end value.

  STEP is optional and if ommited a step of 1 is assumed.  If STEP is provided
then the expression following STEP is added to the loop variable each time
through the loop.

  NEXT provides the endpoint of the loop.  The variable referenct in NEXT is
optional if the NEXT is referring to the FOR at the same level.  It is also
possible to specify a variable for NEXT that is in an outer loop, in this case
all loops inside of the referenced outer loop will cease to exist and 
execution continues with the referenced loop.

Examples:
10 FOR I=1 TO 10
20 PRINT I;" ";
30 NEXT I

RUN
   1 2 3 4 5 6 7 8 9 10

10 FOR I=1 TO 10 STEP 3
20 PRINT I;" ";
30 NEXT I

RUN
   1 4 7 10

10 FOR I=1 TO 5
20 FOR J=1 TO 10
30 PRINT I,J
40 IF J=2 NEXT I:END
50 NEXT J
60 PRINT "WILL NEVER SEE THIS"
70 NEXT I

RUN
   1       1
   1       2
   2       1
   2       2
   3       1
   3       2
   4       1
   4       2
   5       1
   5       2

  This last example may require a bit of explanation so that you will
understand why the results are the way they are.  In line 40 we are testing
for J=2 and if so we execute NEXT I.  At this point loop J is the innermost
nested loop, but by using NEXT I this will terminate the J loop right where
it is and start the next iteration of the I loop.  When the I loop finishes
the END following the NEXT I is the next executed statement, which ends the
program so the print at line 60 will never be seen.

-------------------------------------------------------------------------------
GOSUB expr

  The GOSUB command allows normal program execution to be interrupted so that
a subroutine could be executed.  

  Like GOTO, Rc/Basic allows for computed GOSUB.  Example: GOSUB B*100

  If the target line of GOSUB does not exist, then an error 3 will result.

  When a RETURN command is encountered, program execution will continue with
the statement following the GOSUB.

-------------------------------------------------------------------------------
GOTO expr

  The GOTO command changes the order of execution.  Normally a program is
executed from the lowest numbered line to the highest numbered line.  When
a GOTO is encountered a jump is taken to the specified line.

  Rc/Basic allows for computed GOTO, so expr can be a standard expression that
evaluates to a line number.  Example: GOTO A*1000

  If the target line of a GOTO, either excplicit or computed, does not exist
then an error 3 will result and program execution will be terminated.

  GOTO can also be used in direct mode in order to start a program from a
specified line.  For example:

10 A=5
20 PRINT A

RUN
   5

A=100
GOTO 20
   100

  Note that when GOTO is used to start execution that variable and heap space
are not cleared like it is when using RUN to start a program.

-------------------------------------------------------------------------------
IF expr [THEN] statement

  The IF command allows for descisions within a program.  In Rc/Basic the 
THEN is optional.  If when expr is evaluated and results in a nonzero
value the statements following THEN will be executed.  If the results of the
expression are zero then execution will follow through to the line following
the line containing the IF statement.

Example:

10 A=5
20 IF A<10 PRINT "A":PRINT"B"
30 PRINT "C"

RUN
   A
   B
   C

Change line 10 to:

10 A=100

RUN
   C

  Note:  IF/THEN statements can be nested.

-------------------------------------------------------------------------------
INPUT ["prompt";]var[,var...]

  This statement allows a program to get input from the user.  If the optional
prompt is specified, it will be printed before the program queries for input.

  Multiple variables may be input at the same time.

  The expression evaluator is used when reading input values, therefore you
can specify expressions for input values.

  If not enough values were given for the number of variables specified in the
INPUT command, then multiple queries will be made of the user.

  If the user gives more values than INPUT is expecting, remaining values will
be read by the following INPUT commands.

Examples:

10 B=5
20 INPUT "VALUE=";A
30 PRINT A

RUN
   VALUE=? 10
   10

RUN
   VALUE=? B*5
   25

10 INPUT "VALUES=";A,B
20 PRINT A,B

RUN
   VALUES=? 4,5
   4       5

RUN
   VALUES=? 4
   ? 5
   4       5

10 INPUT "VALUE 1=";A
20 INPUT "VALUE 2=";B
30 PRINT A,B

RUN
   VALUE 1=? 5
   VALUE 2=? 7
   5      7

RUN
   VALUE 1=? 5,7
   VALUE 2=
   5      7

-------------------------------------------------------------------------------
LET varname = value
  Let allows values to be assigned to variables.

  The LET is actually optional in Rc/Basic.

Examples:

LET A=5*(2+7)

A=10*B

-------------------------------------------------------------------------------
LIST

  This command will list the entire contents of program memory.

LIST line

  This command will list only the specified line number.  If the specified
line number does not exist, then an error will be generated.

LIST start-

   List lines starting from the specified line up to the end of the program.
The specified line does not need to exist.  If it does not exist then the first
line to be listed will be the next highest line number that does exist.

LIST -end

  This form of the list command will list from the start of the program up to
and including the specified line number.  The ending line number need not
exist.

  LIST start-end

  The final form of the LIST command allows you to specify a range of lines to
show.  Neither the start or end lines need to exist.

-------------------------------------------------------------------------------
NEW

  NEW clears the program space of the current program.  Issue this command when
you desire to erase the current program and begin a new one.  If this command
is used inside of a program, it will cause memory to be cleared and program
execution to end.

-------------------------------------------------------------------------------
ON expr GOTO line1,line2,line3,...,linen                   L2 Only

  This form of the GOTO command will evalute the given expression to see which
of the specified line numbesr to jump to.  If the expression evaluates to 1
then the first line will be jumpted to, if the expression evaluates to 2 then
the second line will be jumped to and so forth.  If the expression evaluates
to less than 1 or greater than the number of line numbers given execution will
fall through to the next statement.

  Just like in the standard GOTO, the line numbers can be computed.

Examples:

10 A=2
20 ON A GOTO 100,200,A*100
30 PRINT "NONE"
99 END
100 PRINT "100":GOTO 99
200 PRINT "200":GOTO 99
300 PRINT "300":GOTO 99

RUN
    200

Change line 10 to

10 A=0

RUN
   NONE

Change line 10 to

10 A=4

RUN
   NONE

Change line 10 to

10 A=3

RUN
   300

-------------------------------------------------------------------------------
OUT port,value

  The OUT command allows you to write the specified value out to the 
specified port.  port can be from 1 through 7.

-------------------------------------------------------------------------------
POKE address,value

  Poke will write the specified value into the specified address in memory.
Care must be taken when using POKE.  If you POKE a value into a critical 
location it could lock the machine and require a reset.

-------------------------------------------------------------------------------
PRINT expr_list

  The print command allows a program to output values to the terminal.  The
expression list may consist of no elements or multiple elements.  When no
expressions are given PRINT will just move the cursor down a line on the
terminal.
  
  When multiple expressions are provided, each expression must be seperated
by either a , or ; character.  Whenever a , is encountered a <TAB> character
is sent to the terminal which will tell the terminal to move the cursor to the
next tab stop.  When ; is encountered no cursor movement will occur.

  Both , and ; can also be the last character of the expression list and will
have the effect of preventing the automatic carriage return at the end of the
PRINT statement.

Examples:

10 PRINT "ANSWER=";5+7

   ANSWER=12

10 PRINT "A","B";"C"

   A      BC

10 PRINT "A"
20 PRINT "B"

   A
   B

10 PRINT "A";
20 PRINT "B"

   AB

10 PRINT "A",
20 PRINT "B"

   A      B

-------------------------------------------------------------------------------
RANDOM                                                     L2 Only

  This statement allows the random number generator to be reseeded.  The user
will be prompted for a value to reseed the generator with.  The same seed value
will always generate the same string of random numbers.

-------------------------------------------------------------------------------
READ var,var,var,...                                       L2 Only

  The READ statement will read values from the current DATA pointer into the
specified variables.  It is not necessary to match the number of variables in
the READ list to a specific DATA statement.  For all practical purposes it
does not matter how many DATA statements the data is spread over, it is all
considered linear to the READ statement.

  If an attempt to read a data element beyond the last DATA statement is made
then an error 9 will occur.

  The READ/DATA set of statements makes it easy to initialize variables.

Examples:

10 DATA 5,10,15,20,25,30
20 READ A,B,C
30 PRINT A,B,C
40 READ A,B
50 PRINT A,B
60 READ A
70 PRINT A
80 READ A

RUN
   5       10      15
   20      25
   30

   ERROR:9 in line 80

-------------------------------------------------------------------------------
REM remarks

  This statements marks everything else on the same line following as being
a remark.  Program execution will continue with the next line of the program.

-------------------------------------------------------------------------------
RESTORE [line]                                             L2
  The restore command will reset the DATA pointer used by the READ statement.
If no line is specified, then the DATA pointer will be set to the first data
item of the first DATA statement in the program.

  If a line number is specified then the DATA pointer will be set to the first
item of the first DATA statment line that is on or later than the specified 
line.  Note, it is not necessary to specify the the DATA line number exactly
it can be a lower number than what you want to set.  The line referenced by
the RESTORE command must however exist even if it is not a DATA line.  If the
line does not exist at all an error 3 will result.

10 DATA 1,2,3,4,5
20 DATA 10,11,12,13
30 READ A,B,C
40 PRINT A,B,C
50 RESTORE
60 READ A,B,C
70 PRINT A,B,C
80 RESTORE 20
90 READ A,B,C
100 PRINT A,B,C

RUN
   1      2      3
   1      2      3
   10     11     12

-------------------------------------------------------------------------------
RETURN
  
  This command will return execution back to the statement following the last
executed GOSUB command.

  If there are no more GOSUB targets left on the stack then an error 4 will
result and the program will be terminated.

Example:

10 PRINT "A"
20 GOSUB 100
30 PRINT "C"
99 END
100 PRINT "B"
110 RETURN

RUN
    A
    B
    C

-------------------------------------------------------------------------------
RUN

  RUN begins execution of the program in memory.  Execution always starts with
the lowest line number, and all variables and heap space is cleared.  This 
command may be used inside of a program in order to restart the program from
the cleared state.

-------------------------------------------------------------------------------


Advanced Techniques:
--------------------
  
Using VARPTR:
-------------

  VARPTR is a function that allows you to determine where in memory something
is stored.  For the three different variable types you can look at, here is
what VARPTR will give you:

Integer Variable - Example: VARPTR(A).
  When obtaining the address of an integer variable, VARPTR will return the
address where the variables value is actually stored.  Here is an example:

10 I=5
20 PRINT PEEK(VARPTR(I))
30 PRINT PEEK(VARPTR(I)+1)

RUN
   0
   5

  Integer variables are stored with the MSB first in memory and then the LSB
second.

  Using the address you get from VARPTR, you can also change the data in a
variable.

10 I=5
20 POKE VARPTR(I)+1,10
30 PRINT I

RUN
   10

String Variable - Example: VARPTR(A$)
  When using VARPTR on a string variable, the address returned points to the 
address of where the string data is stored.  So unlike integer variables, 
there is one level of indirection in the address. So for example:

10 A$="ABC"
20 M=VARPTR(A$)
30 M=PEEK(M)*256+PEEK(M+1)
40 POKE M,49
50 PRINT A$

RUN
   1BC

  In this example, line 30 is what takes the address that VARPTR returned and
then reads the address of the actual string data.  Just like in integer values,
address values are stored MSB first.

  Unlike many other BASICs, Rc/Basic does not use a length byte for strings.
This has the benefit that strings can be longer than 255 characters.  Strings
are terminated with a zero byte, so for example "ABC" would be stored in
memory as 41 42 43 00

Array Variable - Example: VARPTR(A(0))
  When using VARPTR on an array element, the address where that element's data
is stored is returned.  Here is an example:

10 DIM A(10)
20 A(0) = 5
30 POKE VARPTR(A(0))+1,10
40 PRINT A(0)

RUN
   10

Machine Language Subroutines:
-----------------------------

  Using USR() it is possible to extend the capabilities of BASIC with your
own machine language subroutines.

  When writing ML subroutines for use with Rc/Basic you must make sure that
all registers modified by the ML subroutine be preserved on return back to
BASIC.

  Control will be transferred to the ML subroutine with R3 as the active
program counter. R2 will point to BASIC's stack.  R4, R5, and R6 will all
have the values for using SRET and SCAL from the BIOS.

  In order to return back to BASIC you must execute a SEP RD.

Machine language programs inside of strings:
--------------------------------------------

Strings make a good place to store small machine language programs.  Since
when the string is created the space in memory is allocated and you no longer
need to worry if the subroutine gets clobbered by the stack, heap, or variable
storage.

There are two basic techniques for doing this, dynamic strings and static
strings.  In dynamic strings, you want to create space on the heap where
the string will be stored.  create the string using a string expression, the
resulting string is guaranteed to be on the heap.  After the string is created
you just poke your ML subroutine into the string space.  The advantage of
using dyanmic strings is that the original program source is not affected by
the POKEing of the ML subroutine.  The disadvantage is that the ML subroutine
must be loaded into the string every run.  Here is an example of a program
using the dyanmic string technique:

10 A$="     "+" "
20 M=VARPTR(A$)
25 M=PEEK(M)*256+PEEK(M+1)
30 FOR I=0 TO 4:READ N:POKE M+I,N:NEXT
40 I=USR(M)
50 DATA 227,100,174,226,221

In the static string technique, you want strings that are fixed into the
program space.  Normally when a string is assigned as a constant in the
program the string in the program code is used as the string space for the
variable, and it is not allocated on the heap.  The advantage of this method
is that once the strings are loaded with the ML routine, you need not load 
them again between runs.  When the program is saved, it will be saved with
the ML routines intact in the strings.  the disadvantage is that you usually
end up with unprintable characters in the strings which when the program is
listed can cause havoc with the terminal.  Here is an example of using 
the static strings method:

Step 1.

10 A$="     "
20 M=VARPTR(A$)
25 M=PEEK(M)*256+PEEK(M+1)
30 FOR I=0 TO 4:READ N:POKE M+I,N:NEXT
50 DATA 227,100,174,226,221

Notice the difference in the definition of A$?  in this version since the
assignment does not involve an expression, the string pointer will point to
the constant in the program text itself.

After running this program take a look at line 10

LIST 10
10 A$="cd.b]"

The values now in the string were put there by the POKEs and now constitutes
the ML subroutine as part of the program code.

now delete lines 30 and 50

and add this line:

50 i=usr(m)

You should now have this:

10 A$="cd.b]"
20 M=VARPTR(A$)
25 M=PEEK(M)*256+PEEK(M+1)
40 I=USR(M)

This program will now do what the first program did, but now you can save this
and not ever need to load the ML subroutine again since it is now part of the
program.

-------------------------------------------------------------------------------

Error Codes:
------------
0        Break was pressed (IN button)
1        Statement not allowed in direct mode
2        Syntax Error
3        Invalid line number
4        Return without Gosub
5        Value error
6        File error (Elf/OS only)
7        INVLP
8        NEXT without FOR
9        No DATA for READ
10       Out of Memory
11       Bad Dimension
12       Unsupported feature

