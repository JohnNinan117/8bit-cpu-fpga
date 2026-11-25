\documentclass[11pt]{article}
\usepackage[margin=1in]{geometry}
\usepackage[T1]{fontenc}
\usepackage{booktabs}
\usepackage{enumitem}
\usepackage{hyperref}

\title{Custom 8-Bit CPU --- Instruction Set Architecture}
\author{EECS 3216 Final Project}
\date{}

\begin{document}
\maketitle

\section{Overview}

This project implements a custom 8-bit microprocessor in Verilog on the
DE10-Lite FPGA board. The processor uses a multicycle, non-pipelined
architecture with a fixed 16-bit instruction format.

\subsection*{CPU Specifications}

\begin{center}
\begin{tabular}{ll}
\toprule
Component & Specification \\
\midrule
Data width & 8 bits \\
Instruction width & 16 bits \\
General-purpose registers & 4 (R0--R3) \\
Register width & 8 bits \\
Program Counter (PC) & 5 bits \\
Instruction memory & $32 \times 16$-bit ROM \\
Instruction count & 8 \\
Architecture & Multicycle, non-pipelined \\
Memory & Preloaded instruction ROM \\
Output & 8-bit output register \\
\bottomrule
\end{tabular}
\end{center}

\section{Instruction Format}

All instructions are 16 bits wide.

\begin{center}
\begin{tabular}{lll}
\toprule
Bits & Field & Description \\
\midrule
15--12 & Opcode & Selects the instruction \\
11--10 & Rd & Destination/selected register \\
9--8 & Rs & Source register \\
7--0 & Immediate & Constant or branch address \\
\bottomrule
\end{tabular}
\end{center}

Instruction layout:

\begin{center}
\begin{tabular}{|c|c|c|c|}
\hline
Opcode & Rd & Rs & Immediate \\
4 bits & 2 bits & 2 bits & 8 bits \\
\hline
\end{tabular}
\end{center}

Register encoding:

\begin{center}
\begin{tabular}{ll}
\toprule
Register & Encoding \\
\midrule
R0 & \texttt{00} \\
R1 & \texttt{01} \\
R2 & \texttt{10} \\
R3 & \texttt{11} \\
\bottomrule
\end{tabular}
\end{center}

Unused instruction fields are encoded as zero.

\section{Instruction Set}

\begin{center}
\begin{tabular}{lll}
\toprule
Instruction & Opcode & Operation \\
\midrule
\texttt{LDI}  & \texttt{0001} & Rd = immediate \\
\texttt{ADD}  & \texttt{0010} & Rd = (Rd + Rs) mod 256 \\
\texttt{SUB}  & \texttt{0011} & Rd = (Rd $-$ Rs) mod 256 \\
\texttt{AND}  & \texttt{0100} & Rd = Rd \& Rs \\
\texttt{OR}   & \texttt{0101} & Rd = Rd $|$ Rs \\
\texttt{JNZ}  & \texttt{0110} & Jump if Rd $\neq$ 0 \\
\texttt{OUT}  & \texttt{0111} & Output = Rd \\
\texttt{HALT} & \texttt{1000} & Stop execution \\
\bottomrule
\end{tabular}
\end{center}

\subsection{LDI --- Load Immediate}
Loads an 8-bit constant into the selected register.
\begin{verbatim}
LDI R0, 5
\end{verbatim}
Result: R0 = 5. Rs is unused and must be zero.

\subsection{ADD --- Addition}
Adds two registers and stores the result in Rd. The result wraps modulo 256.
\begin{verbatim}
ADD R0, R1
\end{verbatim}
Result: R0 = (R0 + R1) mod 256

\subsection{SUB --- Subtraction}
Subtracts Rs from Rd and stores the result in Rd. The result wraps modulo 256.
\begin{verbatim}
SUB R0, R1
\end{verbatim}
Result: R0 = (R0 $-$ R1) mod 256

\subsection{AND --- Bitwise AND}
\begin{verbatim}
AND R0, R1
\end{verbatim}
Result: R0 = R0 \& R1

\subsection{OR --- Bitwise OR}
\begin{verbatim}
OR R0, R1
\end{verbatim}
Result: R0 = R0 $|$ R1

\subsection{JNZ --- Jump if Not Zero}
Checks the selected register.
\begin{verbatim}
JNZ R0, 4
\end{verbatim}
If R0 $\neq$ 0, PC becomes 4. Otherwise, execution continues at the next
instruction.

The branch target is stored in immediate[4:0] and is an \emph{absolute}
ROM address. Immediate[7:5] and Rs are unused and must be zero.

JNZ tests the register directly, not the Zero flag.

\subsection{OUT --- Output Register}
Copies a register value into the CPU output register.
\begin{verbatim}
OUT R0
\end{verbatim}
Result: Output = R0. Rs and the immediate are unused and must be zero.

The output register connects to the FPGA's seven-segment displays and VGA
monitor.

\subsection{HALT --- Stop Execution}
\begin{verbatim}
HALT
\end{verbatim}
Stops instruction execution until reset. All fields other than the opcode
are unused and must be zero.

When HALT executes, the HALT status is set and the PC stays at the address
of the HALT instruction. While halted, KEY1 presses and the automatic-mode
clock enable have no effect. Only reset (KEY0) resumes execution.

\section{Arithmetic and Status Flags}

All arithmetic uses 8-bit results.

\subsection{Overflow and Underflow}
Only the lowest 8 bits of ADD/SUB results are stored. Arithmetic wraps
modulo 256. Examples:
\begin{verbatim}
255 + 1 = 0
3 - 5   = 254
\end{verbatim}

\subsection{Zero Flag (Z)}
The Zero flag updates after ADD, SUB, AND, or OR.
\begin{itemize}[nosep]
  \item Z = 1 if the resulting 8-bit value is zero.
  \item Z = 0 otherwise.
\end{itemize}
LDI, JNZ, OUT, and HALT do not modify Z.

\subsection{HALT Status}
A separate HALT status signal (LEDR9) indicates that the processor has
stopped execution, whether by a HALT instruction or by a reserved opcode
(Section~\ref{sec:reserved}).

Carry and signed-overflow flags are not implemented in the initial design.

\section{Program Counter and ROM}

The 5-bit PC addresses 32 instruction words.

\begin{center}
\begin{tabular}{ll}
\toprule
ROM Addresses & Program \\
\midrule
0--15 & Arithmetic demonstration \\
16--31 & Countdown demonstration \\
\bottomrule
\end{tabular}
\end{center}

SW1 selects the initial PC value during reset:
\begin{itemize}[nosep]
  \item SW1 = 0: PC starts at 0.
  \item SW1 = 1: PC starts at 16.
\end{itemize}
SW1 is sampled only while reset is held. Changing SW1 during execution has
no effect until the next reset.

The PC normally increments after each instruction. JNZ can replace the next
PC with a branch target. PC arithmetic is 5-bit, so incrementing 31 wraps
to 0. Both demonstration programs must HALT before running into the next
program's address region. Unused ROM words are filled with \texttt{0x0000},
a reserved opcode, so a runaway program halts.

\section{Reset Behavior}

On active-low reset (KEY0):
\begin{itemize}[nosep]
  \item R0--R3 are cleared to 0.
  \item Output register is cleared to 0.
  \item Zero flag is cleared to 0.
  \item HALT status is cleared.
  \item Last-completed-instruction register is cleared.
  \item PC loads 0 or 16 according to SW1.
  \item CPU returns to its initial execution state.
\end{itemize}

\section{Example Programs}

\subsection{Program 1: Addition}
\begin{verbatim}
LDI R0, 5
LDI R1, 3
ADD R0, R1
OUT R0
HALT
\end{verbatim}
Expected output: \texttt{0x08} (HEX1--HEX0 show \texttt{08}).

\subsection{Program 2: Countdown}
\begin{verbatim}
    LDI R0, 9
    LDI R1, 1
LOOP:
    OUT R0
    SUB R0, R1
    JNZ R0, LOOP
    OUT R0
    HALT
\end{verbatim}
Expected outputs: \texttt{0x09}, \texttt{0x08}, \ldots, \texttt{0x01},
\texttt{0x00}.

The assembler/ROM definition resolves LOOP to the correct absolute
instruction address (address 18 when the program starts at 16).

\section{Execution and Display}

The CPU supports two execution modes:
\begin{itemize}[nosep]
  \item Manual mode (SW0 = 0): One KEY1 press executes one complete
        instruction.
  \item Automatic mode (SW0 = 1): Instructions execute automatically at a
        human-observable rate.
\end{itemize}

The VGA dashboard displays:
\begin{itemize}[nosep]
  \item Next Program Counter
  \item Last completed instruction
  \item Registers R0--R3
  \item Output register
\end{itemize}

The seven-segment displays show the output register. LEDs indicate the PC,
Zero flag, and HALT status.

\section{Reserved Opcodes}
\label{sec:reserved}

Opcodes \texttt{0000} and \texttt{1001}--\texttt{1111} are reserved.

An unsupported opcode causes execution to halt, exactly as HALT does: the
HALT status is set and the PC stays at the address of the reserved
instruction.

\section{Implementation Notes}

The CPU core will be implemented separately from the DE10-Lite hardware
interfaces. Planned hardware modules include:
\begin{itemize}[nosep]
  \item \texttt{alu.v}
  \item \texttt{register\_file.v}
  \item \texttt{instruction\_rom.v}
  \item \texttt{control\_unit.v}
  \item \texttt{cpu\_core.v}
  \item \texttt{vga\_renderer.v}
  \item \texttt{top.v}
\end{itemize}

Simulation testbenches will verify instruction execution before FPGA
integration.

\end{document}