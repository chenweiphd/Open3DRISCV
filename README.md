# Open3DRISCV（V-Rio）——the First Open Source 3D RISC-V Processor

**1 Overview**

This 3D RISC-V CPU（We call it V-Rio）is a template of a serise of 3D CPU. One could contain 1 to several banks of CPU cores， from small silicon area to large size. Each bank contains 16 RISC-V cores and 4 V-Cache die.

![image-20250616130555875](https://raw.githubusercontent.com/chenweiphd/typopic/master/image-20250616130555875.png)

Core: 16NB cores（NB means Number of Banks） with 64bit data width, 12 stage pipeline with 3 Issues/ 8 execution， support RV64GC instruction set. 

NoC: support AMBA CHI protocal with verion 0050E.b，implement HN-F, HN-I, RN-I, SN-F and XP.

Cache: 64K instruction and data caches with cache coherency support. Hardware cache coherency

ensures the consistency of all caches efficiently. The cluster shared L2 Cache is 1MB. Software and hardware collaborative optimization of data consistency between TLB, I-Cache and D-Cache.

 

**1.1 Processor Features**

The main features of the 3D RISC-V CPU are:

 

| **Level**   | **Item**                      | **Description**                                              | **Comment**                                                  |
| ----------- | ----------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Chip**    |                               |                                                              |                                                              |
|             | Core                          | 16NB                                                         | 2M， NB=No. of Bank                                          |
|             | Cluster                       | 8NB                                                          | 1 Cluster has 2 Cores ( or 4  Cores in another version)      |
|             | Bitwidth                      | 64                                                           |                                                              |
|             | ISA                           | RV64GC                                                       |                                                              |
|             | NoC                           | AMBA CHI                                                     | version 0050E.b， HN-F, HN-I, RN-I, SN-F and XP              |
|             | No. of V-Cache                | 4NB  Same to DDR                                             | Shared Cluster Cache（LLC）, memory die bonding to logic  die with ubump |
|             | DDR version                   | 4                                                            |                                                              |
|             | DDR bitwidth                  | 128                                                          |                                                              |
|             | No. of DDR interface          | 4NB                                                          |                                                              |
|             | No. of PCIE interface         | 2NB                                                          |                                                              |
|             |                               |                                                              |                                                              |
| V-Cache     |                               |                                                              |                                                              |
|             | V-Cache density               | 8MB?                                                         |                                                              |
|             | Bitwidth                      | 128                                                          |                                                              |
|             | No.of bank                    |                                                              |                                                              |
|             | Sub-array configuration       |                                                              |                                                              |
|             | Coherence protocol            | CHI                                                          |                                                              |
|             |                               |                                                              |                                                              |
| **Cluster** |                               |                                                              |                                                              |
|             | No. of core                   | 2                                                            | （~8 mpw seat）                                              |
|             | Coherence protocol            | CHI                                                          |                                                              |
|             | L2 cache                      | 1MB                                                          | Per cluster                                                  |
|             | L2 cache line size            | 64B                                                          |                                                              |
|             | L2 cache ECC error protection | support                                                      |                                                              |
|             | Bus Interface                 | CHI                                                          |                                                              |
| **Core**    |                               |                                                              |                                                              |
|             | Core area estimation @12nm    | 7.6mm2                                                       | Estimate core area by L3 cache  area（~2 mpw seat）          |
|             | Pipeline stage                | 12                                                           |                                                              |
|             | Issue                         | 3                                                            |                                                              |
|             | Execution                     | 8                                                            |                                                              |
|             | I-Cache  /each core           | 64KB                                                         | with cache coherency support， can be configured as 32KB     |
|             | I-Cache  /each core           | 64KB                                                         | with cache coherency support,  can be configured as 32KB     |
|             | Branch target buffer          |                                                              |                                                              |
|             | ISA                           | RV64GC？                                                     |                                                              |
|             | Memory management unit        | Sv39 memory management？                                     |                                                              |
|             | Bus interface                 | AXI4-128 master interface？                                  |                                                              |
|             | Interrupt controller          | Configurable Platform Level  Interrupt Controller (PLIC)     |                                                              |
|             | Floating-point Unit           | Support RISC-V F, D  instruction extension  Support IEEE 754-2008  standard? |                                                              |

NoC refrence：https://github.com/RV-BOSC/OpenNoC/tree/master

**1.2 Block Diagram**


![image](https://github.com/user-attachments/assets/dd0d459e-771d-474d-bda9-e89073ca490e)

![image](https://github.com/user-attachments/assets/630b4d17-9d25-41e1-a343-ef3cd9bc4fe6)


**1.3 Major Components**

The following list describes the major components or abbriviation of the 3D RISC-V CPU design

| Bieviation   | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| ALU          | Arithmetic Logic Unit                                        |
| NoC          | Network On Chip                                              |
| ACPU         | Application Central Process  Unit                            |
| SCU          | Snoop Control Unit                                           |
| SF           | Snoop Filter                                                 |
| PLIC         | Platform Level Interrupt Controller                          |
| HN-F，HN-I， | Fully Coherent Home Node/Non-  Coherent Home Node            |
| RN-I，       | IO Coherent Request Node                                     |
| SN-F，SN-I   | A Subordinate Node type used  for Normal Memory/A Sunordinate  Node used for Peripherals or Normal memory |

**2 Manycore Top Level**

**2.1 ManycoreDiagram**

The top of the 3D RISC-V CPU processor design is 8 CPU cluster. The CPU cluster instantiates

2 of CPU core top. 

**2.2 NoC and Interface**

**2.2.1 NoC Overview**

The manycore CPU system leverages the OpenNoC interconnect, an AMBA CHI protocol-compliant (version 0050E.b) Network-on-Chip (NoC) designed to connect multiple cores, memory controllers, and peripherals. The OpenNoC implementation includes key components: HN-F (Home Node-Fully Coherent), HN-I (Home Node-Interface), RN-I (Request Node-Interface), SN-F (Slave Node-Fully Coherent), and SXP (Scalable eXtensible Protocol) routers. 

The system supports scalable topologies (e.g., mesh, ring) and provides configurable parameters for optimizing performance, coherence, and resource utilization.

**2.2.2 HNF Function**

The HN-F (hereinafter referred to as HN-F) included in this project implements the POC (Point of Coherence) and PoS (Point of Serialization) functions specified by the CHI protocol (see CHI eb protocol 1.6 for details). It contains a configurable LLC cache and a Snoop Filter (SF) that can reduce the number of SNP messages sent. Other functions supported by HN-F are as follows:

\1.   CHI Transaction in the table below

\2.   UC, SC, UD, I cache line status in CHI protocol

\3.   Exclusive access

\4.   QoS

 HN-F receives Req messages from the RXREQ channel. Each received Req message corresponds to a Transaction, and a Transaction may include multiple Rsp, Snp and Dat messages. HN-F cooperates with RN and SN-F to complete the entire Transaction.

HN-F can be viewed as a state machine that behaves as follows:

\1.   Read and update internal cache data and status (including LRU)

\2.   Read and update SF

\3.   Read and update the exclusive monitor

\4.   Read and update QoS (including internal arbitration related registers) related registers

\5.   Send Req, Rsp, Snp and Dat messages

HN-F chooses to complete a certain behavior at a certain time based on its internal state and the received message. The connection between the state and the behavior is not fully described here:

\1.   The cache block status determines which type of message to send and the cache block update status. The cache block data determines the content of the Data field in the Dat message.

\2.   The SF content determines the fields and quantity of the Snp message to be sent.

\3.   Exclusive Monitor determines the content of the RespErr field, etc.

\4.   QoS related registers determine when a message is sent, etc.

\5.   The received Req, Rsp, and Dat messages determine the transaction process (this process is also achieved by modifying the MSHR status bit)

 

HN-F consists of the following five components. The following figure shows the HN-F data path:

（1）Link Interface

  LI (Link Interface) includes the interface for HN-F to interact with the outside world, and implements the sending and receiving of Flit (CHI protocol messages) based on the CHI protocol channel specification. The four external channels of LI are: RXREQ, RXRSP, RXDAT, TXREQ, TXRSP, TXSNP, TXDAT. The main functions of LI are the packet assembly function of the Network Layer specified by the protocol and the flow control function of the Link Layer (14.2). In addition, it is also responsible for arbitrating the message sending requests from different sources inside HN-F and unpacking the RX channel.

(2) MSR

  MSHR is the control center of HN-F. It receives messages from LI, requests from BIQ (Back Invalidation Queue), and results returned by Cache Pipeline, and modifies its internal control bits. In each cycle, MSHR determines its behavior based on the status of its internal control bits: sending requests to read or update LLC and SF to Cache Pipeline, and sending requests to LI to send outbound messages.

  The internal storage structure of MSHR is a register stack with multiple MSHR entries. Each transaction (and the replacement transaction it brings) corresponds to one of them. Each entry includes the control bits required by all transactions, as well as some information of the transaction itself, such as SrcID and address. This allows MSHR to process multiple transactions at the same time. When Req arrives, it is determined whether it can enter MSHR based on QoS.

  Due to the existence of parallelism, in order to realize PoC and PoS functions, MSHR also includes a conflict handling mechanism: hibernate the later transactions of the same address until the earlier transaction is completed.

  Since the LI external channel and Cache Pipeline can only complete one transaction corresponding operation per cycle, MSHR also implements the arbitration function for these structures.

(3) Data Buffer

  DBF (Data Buffer) is a register stack, with the same number of items as MSHR, one-to-one correspondence. Each item includes data and Byte Enable (meaning the same as BE in the protocol). The function of DBF is to temporarily store the data involved in the transaction. When data is read from LLC or arrives from RXDAT, it will be written to DBF; when data needs to be written to LLC or sent by RXDAT, DBF is read. For exchange data, see the CaChePipeLine document.

(4) SRAM

  The HN-F's SRAM is used to store L3 data and status, as well as SF content, to support two major functions of CPL:

\1.   A coherent L3 cache

\2.   Reduce the number of SNP messages sent

  The first function relies on Data SRAM to store data, Tag SRAM maintains the correspondence between a Cache Line and a physical address and the state of this Cache Line in L3, and LRU SRAM records the access history information of different Ways to determine the replacement way. The second function relies on SF SRAM. Each Cache Line describes the set of all possible states of the data corresponding to its corresponding physical address in RN-F. If a certain address does not hit SF SRAM and BIQ does not hit, it can be considered that the data corresponding to the address does not exist in any RN-F cache.

  The SRAM used in the HN-F design is a single-port SRAM. Its read and write are completed in one shot. The read request enters the SRAM at the start of T0, and the read data is available at the start of T1. The write request and write data enter the SRAM at the start of T0, and the write data can be read at the start of T1.

(5) CachePipeLine

  CPL (Cache Pipeline) is responsible for updating the L3 data status and SF. CPL is a multi-stage non-blocking pipeline that accepts a request from MSHR every cycle and returns a result of the previous request to MSHR. CPL only accepts a small number of message fields and control bits that it needs from MSHR, and returns to MSHR the L3 status required by MSHR and the target number of Snp messages to be sent.

  CPL connects all SRAM ports except the Data SRAM data port and is responsible for reading and writing these SRAMs, as well as calculating new states.

CPL uses the hazard mechanism to ensure that the update of cache block status and SF is atomic. Since there is a certain interval between the reading and writing of SRAM, there may be another read request after a cache line is read but before it is written, and this read request may want to modify the same Set and Way as the previous request. CPL's hazard mechanism avoids the subsequent request from reading outdated information by marking the subsequent request with retry.

  Due to the existence of Silent Evict, CPL also includes a BIQ (Back Invalidation Queue), which is used to record the address of the replaced cache line when SF is full and misses, SF has been updated but RN-F has not been actually invalidated.

  In this way, when the request for the address replaced by SF that needs Snoop hits the BIQ, multicast is selected to avoid missing an RN-F that still caches the address.

![image](https://github.com/user-attachments/assets/65f4dbf1-80f1-492a-b7d5-047a0687efe9)

 

**3 CPU Core**

**3.1 Core Pipeline Stages and Functions**

 

The CPU core implements a 12-stage dual-issue pipeline 64bit high-performance processor architecture. The following figure shows thepipeline stages of the processor.

![image](https://github.com/user-attachments/assets/cbe21815-12b5-49f5-96f9-911711615e5f)

 

**3.2 Floorplan or Core**

Die Floorplan (This figure contains 2 banks)

 

VC means V-Cache in the figure.

Red represents Cluster (approximately 4mm ² area @12nm).Orange represents NoC nodes.

Choose 1 out of 3 corresponding relationships for each NoC node.

1) 2 clusters (4 cores in total)

2) 1 DDR + 1 PCIe

3) 1 DDR only (PCIe vacancy on the other side)

Each node is only connected to the nearest IP core. Totally 32-core CPU area about 100-130mm ² @12nm

 

**3.3 Memory Management Unit (MMU)**

•    Sv39 virtual memory systems supported.

•    32/17-entry fully associative I-uTLB/D-uTLB.

•    2048-entry 4-way set-associative shared TLB.

•    Hardware page table walker.

•    Virtual memory support for full address space and easy hardware for fast address translation.

•    Code/data sharing.

•    Support for full-featured OS such as Linux.

•    XMAE (XuanTie Memory Attributes Extension) technology extends page table entries for additional attributes.

**3.4 Platform-Level Interrupt Controller (PLIC)**

•    Support multi-core interrupt control.

•    Up to 1023 PLIC interrupt sources.

•    Up to 32 PLIC interrupt priority levels.

•    Up to 8 PLIC interrupt targets.

•    Selectable edge trigger or level trigger.

**3.5 Float Point Unit (FPU)**

•    RISC-V F and D extensions

•    Support half/single/double precision

•    Fully IEEE-754 compliant.

•    Does not generate floating-point exceptions.

•    User configurable rounding modes.

**3.6 Interfaces**

•    Master AXI (M-AXI)

•    DCP (S-AXI)

•    Debug (JTAG)

•    Interrupts

•    Low power control

**4 Memory Locality Hierarchy**

Each CPU core has its own I-Cache and D-Cache. Two cores share one L2 cache. Data coherence among

multiple cores is maintained by hardware.

**4.1 Memory Hierarchy**

The L1 instruction memory system has the following key features:

•    VIPT, two-way set-associative instruction cache.

•    Fixed cache line length of 64 bytes.

•    128-bit read interface from the L2 memory system.

The L1 data memory system has the following features:

•    PIPT, two-way set associative L1 data cache.

•    Fixed cache line length of 64 bytes.

•    128-bit read interface from the L2 memory system.

•    Up to 128-bit read data paths from the data L1 memory system to the data path.

•    Up to 128-bit write data path from the data path to the L1 memory system.

The L2 Cache has the following features:

•    Configurable size of 256KB, 512KB, TMB, 2MB, 4MB, or 8MB.

•    PIPT, 16-way set-associative structure.

•    Fixed line length of 64 bytes.

•    Optional ECC protection.

•    Support data prefetch.

**4.2 L1 I-Cache**

The L1 I-Cache provides the following features: 

• Cache size: 64 KB, with a cache line size of 64 bytes, 2-way set-associative; 

• Virtually indexed, physically tagged (VIPT); 0

• Data width for access: 128 bits; 

• First-in, first-out (FIFO); 

• Invalidation by I-Cache or cache line supported; 

• Instruction prefetch supported; 

• Way prediction supported; 

• D-Cache snooping after a request misses the I-Cache (this feature can be enabled and disabled)

**4.2 L1 D-Cache**

The L1 D-Cache provides the following features:

• Cache size: 64 KB, with a cache line size of 64 bytes, 2-way set-associative;

• Physically indexed, physically tagged (PIPT);

• Maximum data width per read access: 128 bits, supporting byte, halfword, word, doubleword, and

quadword access;

• Maximum data width per write access: 256 bits, supporting access to any combinations of bytes;

• Write policies: write-back with write-allocate, and write-back with write-no-allocate;

• First-in, first-out (FIFO);

• Invalidation and clearing by D-Cache or cache line supported;

• Multi-channel data prefetch for instructions.

**4.3 L2 Cache**

**4.4 L3 Cache****（****V-Cache****）**

**4.5 Cache Coherence**

For requests with shareable and cacheable page attributes, data coherence between L1 D-Caches of different cores is maintained by hardware. For requests with non-shareable and cacheable page attributes, the CPU does not maintain data coherence between L1 D-Caches. If non-shareable and cacheable pages need to be shared across cores, data coherence must be maintained by software. 

Cluster maintains data coherence between L1 D-Caches of different cores based on the MESI protocol. MESI indicates four states of each cache line in the D-Cache:

 • M: indicates that the cache line is available only in this D-Cache and has been modified (UniqueDirty).

 • E: indicates that the cache line is available only in this D-Cache and has not been modified (UniqueClean). 

• S: indicates that the cache line may be available in multiple D-Caches and has not been modified (ShareClean). 

• I: indicates that the cache line is not available in this D-Cache (Invalid). 

 

**5 PAD Estimation**

![img](data:image/jpeg;base64,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)



**6 3D Structure****（****Package****）**

**6.1 Structure Diagram**

![img](data:image/png;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAoHBwgHBgoICAgLCgoLDhgQDg0NDh0VFhEYIx8lJCIfIiEmKzcvJik0KSEiMEExNDk7Pj4+JS5ESUM8SDc9Pjv/2wBDAQoLCw4NDhwQEBw7KCIoOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozv/wAARCADGAigDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD2aiiigAooooAKKKKACiiigAooooAKKKKACkLBfvED60tYXizH9nw/9df6GgDb8xP76/nR5if31/OvOcD0owPSgD0bzE/vr+dHmJ/fX8685wPSjA9KAPRvMT++v50eYn99fzrznA9KMD0oA9G8xP76/nR5if31/OvOcD0owPSgD0bzE/vr+dHmJ/fX8685wPSjA9KAPRvMT++v50eYn99fzrznA9KMD0oA9G8xP76/nR5if31/OvOcD0owPSgD0bzE/vr+dHmJ/fX8685wPSjA9KAPRvMT++v50eYn99fzrznA9KMD0oA9G8xP76/nR5if31/OvOcD0owPSgD0bzE/vr+dHmJ/fX8685wPSjA9KAPRvMT++v50eYn99fzrznA9KMD0oA9G8xP76/nR5if31/OvOcD0owPSgD0bzE/vr+dHmJ/fX8685wPSjA9KAPRvMT++v50eYn99fzrznA9KMD0oA9G8xP76/nR5if31/OvOcD0owPSgD0bzE/vr+dHmJ/fX8685wPSjA9KAPRvMT++v50eYn99fzrznA9KMD0oA9G8xP76/nR5if31/OvOcD0owPSgD0bzE/vr+dHmJ/fX8685wPSjA9KAPRvMT++v50eYn99fzrznA9KMD0oA9G8xP76/nR5if31/OvOcD0owPSgD0cMG6EH6UtYfhQj+zpV7iU/yFblABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFc74sf91AnoxNdFXLeJn3y+ysB+lUkJswKKKKkYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABSMwVWY9FBJpaSRd8bqOrKR+lAEaXULWkd00ixxSIrBpCFwCMjNK9zbxhS88SBxlSzgbh7etZ8VnerBY+ZBbl7JQoQykrJ8m0nO3gjtwepqheWUttBcW3kRzvdWzIB5bFUJZjtXAPHzd8dM/QA3jcwqCZJEjAfYC7gbj7c/8A16mrI/su4jnklVLefzDIPLlJ2gME56HP3SCPQ9a1gMAD0FABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQB03hR8RzJ6nNdFXK+G32SL7uR+ldVVSWxKe4UUUVJQUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFcfrT+Yu/+9KT/OuruX8u2kf0U1y17AZ4VXdjDZzjNawV4szk/eRi0Va+xp/z8J+n+NH2NP8An4T9P8ankZdyrRVr7Gn/AD8J+n+NH2NP+fhP0/xo5GFyrRVwafkZEuR7LR/Z5/56f+O0/Zy7C5kU6KuGwx1mA+oo+wf9Nh+VHs59g54lOirn9nn/AJ6/+O1m39wbC58kx7wVDBs4zScJJXYKSZNRVD+1R/zx/wDHqP7VH/PH/wAeqCi/RTdOZtQMnymMIByec5q9/Z5/56/+O1ahJq6JckinRTtQRrCATY8wFtpA4xWd/ao/54/+PVLTTsxppl+iqH9qj/nj/wCPVJb35uLiOFYSC7Bc56Uhluirn9nn/nr/AOO0yW1WCMySTYUd9tW4OKu9hJqTstytS0+JbeaQRx3BLHoNhqx/Z5/56/8AjtTBe0V4O68mVNOm7TVmU6Kuf2ef+ev/AI7Uc9vHbgNLNtDHA+TNOUXFc0tETH3nyx1ZXoqaCKG4YrFPuIGT8hFTf2ef+ev/AI7Sgudc0dUOd4O0tGU6KpSaiYpXjaA5ViD81N/tUf8APH/x6kBfoqh/amekBP8AwKtSxha8tVnP7vcThSM01Fyegm0tyKirM9m0UDyK28opIXHWsf8AtTHBgIPu1OUXHcE09i/RVD+1R/zx/wDHqUamW+7bsx9jn+lSMvUVbWwYopMmCRkjHSl+wY6zAfhWns59ieeJToq59hH/AD2H5UCwz0lB+go9nPsHPEp0Vc/s8/8APT/x2j7B/wBNh+VHs5dg5kU6KufYP+mw/Kj7B/02H5Uezl2DmRToq59g/wCmw/Kj+zz/AM9P/HaPZy7BzIuaO2yLf/dkz/KuvByM1yVlD5ELKWzls9MV1Fo/mWsTf7IpzVooiD95k1FFFZGoUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAU9UfbZkf3mAqjp/35PoKn1d+Yo/qa5bxD4juvDkMEtrBDKZ3KsJc8YGeMVpKDlSaXUy5kql2a9zo+g2ih7pRErnALSNya5O5WEXUogwYg52Ec/LniqNz8TLyXalzplhJjkBldse/XirC3H2mMXLIkfmL5hVPurnnA9q+fxuHdJJ2SR9Fl9f2jabbfmLx7Vb0tLN79FviFt8HcSSO3HSsZfHXlZhh0nTpkiwokkjYMw7E/WlPj6QcHRNKBzj7h/xq4ZZVdpaE1Mzp6xsz0izv9KVYrO0uozj5Y0BJNX68rT4gXMTrJHoumo6nIZUYEfrVj/hZ+q/8+Fn/wCP/wCNd0cLWS1seVOtTbvG/wAxnxN/5GG37f6KP/Qmrk7e4e1uYrhCd0Thxz6HNX9f1648Q3qXdzDFE6RiMCPOCMk9/rWXXp04uMEmcknd3PYPttsVRzKqiRQ4z6HkVla55N4kAjIk2E52np0rL0a6N3o9sWOWiTyj/wABPH6Yq7WNZucXC9vQ0o2hJTtfyexn/YV/55t+dVZ2S2kdfKO9Cm3LdS2ccf8AAa2qpzXEKXE/nx7fs8ImV8/eXnOPTBGPxFcP1aS+3L7zv+tRe9OP3F2w8SgQMb2RGfyvOBO1Tjyw2DtyOTnHfjmpv+EnhyT5AEY3Et5vOFcKTjH+0CPx6VnCOOPTvNe12hY/MaFRnB28ge/aqn9oSGCGRYIW8+VY42W5ynzAscnGRjHIxXoe1kcHsqfd/d/wTorTXoLzK4SPdG7oRJu+623kY4OeRWD9jX/nm361EmoR2tkJo7dmcyujqsm7IQku27HzADJ/Sra6grau2n7MDyRIku7hic5H5DNc1eEq1veat2OihUhRv7qlfuRfY1/55t+tbeiPBaWjo7CMmTOG+grJ07UBqEc0ixlFjmMaknO8AAhvbOat1FGjKlPm52/UqvWjVhyqCXobyXMEjBUlVmPQCq2sf8g1/wDeX+dU9P8A+P2P8f5Vc1j/AJBr/wC8v866q8ubDzfk/wAjlw8eXEw9V+Zk6T/yEovx/ka6Sub0n/kJRfj/ACNdJXJlP8B+v6I7M3/jr0/VhWVr/wDqIf8AfP8AKtWsrX/9RD/vn+VdOP8A92n/AF1ObL/96h/XRlfQiBczE8AR8/nWt9ttf+eyVj6N/rLj/riajHQVzZfNxw6+Z0ZjFSxL+X5EerQx3OoySopcED5h9Kp/Yl/55t+taFQ3dx9liWVl3JvVXOcbQTjd+GRUzw8pScudq5UMTGEVH2advIl0aOK1vjI42DYRlvwrd+22v/PZK56Kfzbq4hVOICqls9WIyR+AI/OoftztqLWiRIdhXdul2uQRncq45A+vrXVR5qUOW9/U5a7jVnzWt6HT/bbX/nulc1e2qTX08ioWDuSCD1qvY6s1z5BmhSJZ4mlUrLu2hcZ3DAx1pj62U01rw2j7klVDDu52tghun905x+FKunWSV2vQdCSotvlT9ST7Cv8AzyP51qaGkNnNM8n7ssoAJPXmqEuoomo2tmieYLhWYyA8KMEr9c4P5VbrGlQdOalzt27s2q11Ug48iV+yN1bu3dgqyqWJwBXB+OrvztbS3Vvlt4gDg9zyf6V0tpgXcRPADDNef6ndG+1O6uj/AMtZWYfTPH6Yr0Yyckee48rK2T6n867n4W/8f+pd/wByn/oRrha1/D3iS68OTTy2sEMpnUKwlzxg54x9amrFyg0iou0rntJAIIPQ1i3OkaDZKrXI8oMcKWlbmuN/4Wfqv/PhZ/8Aj/8AjUc3xGvrkAT6Vp8oU5AdWOP1rzZ4OclsvmdtPEqD3aXka+sppyTxDTXDRlPnwxPOfes/8apf8J5N/wBAPS/+/bf40f8ACeTf9APS/wDv23+NccssrN30PQhmlKMUrNl2uy0HUbV7C1tXuUNxgr5ffqcfpXFRXh1CJbxoY4TMNxjiGFXtxUR8ZXGj3H2eHTLKRoT8szqd5zz1B96wwtKo60oR3X+ZvjakHQjOXXb7joJ9bvriZlXywfMEeTAwEeZzGMZPz5AJyOMitzQdUuJbttOl8pvJEu50BG4qUxxnjhzkeorD0a7i8R6Qt1eWFsh3tHsRflwG3d/fn61v6Vp9g0gRrSH9yMxfIPk55x+ODX0fK1TSZ81zJzNPTria4t3afZvSaSP5AQCFYgdfpVuoLaztrNGS2hSJWbcwUYyfWp6yNgooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAxNSfdeMOygCuH+IX/AB5WP/XV/wD0EV2M7+ZPI/qxpqWFnqEqx3lrFcKoJUSIGwfaulvkhfscy96R4myOJDJGyjIAORnp6fnXVaZayR2kZeRCDbLGoAPTk5P5/pXYaj4KiuL15LS1s4oSBhNmMcc9BTF8IXyqFWS3AAwACeP0rwsbWlXSjGL0PewMKdF80prVHlV3YiG4eJSGKEoxfJ3cYzUC2pVwdykBgwyOT1/xr1ZvAszsWZLNmJySVPP6VpaT4SsLWGRb6wsp3ZsqfLBwMe4rspYzRRlBnHWw0VeUZp+R5BmjNe3f8I5oY/5hNn/35Wj/AIRzQv8AoE2X/fpa6PrcOxy+xkeI5or27/hHdC/6BNl/36Wsm58D2M1zJJGbeJHbKoIBhR6daiWMSWkW/uLhh+Z+9K33nK+Gf+QR/wBtW/pWvWpF4OEKbIb5I1znakWB/OpP+ETk/wCgj/5DP+Nczxcm78j+9HSsPTS/iL7mY9U72wW9kgZpCgjb5wBnzE4JU+2Qp/Cuk/4ROT/oI/8AkM/41o2GiW9rb+XOqXL7id7Jzj0pxxLb1jb7iZ0YxV4yv95x8ltG8jzKzpMylRIrH5eOoHTP4VSbRlnlEt1JFKTIjuiwhUfaGHIyeTu6+wr0b+zbH/n0i/75o/s2x/59If8AvkVr7aJjyM87j0aHMa3DmaKGMxQpkrtUnPJB54wPoKjOiEwGMXbhwqIkgXlQu4evOVYj9a9H/s6w/wCfWH/vkVS1HQYbwR/Z5Etdud21fvfrUyrpLRXKjTu7N2OTtbRbQzbD8skm8Lj7o2qoH/jtWK1/+EUf/oJf+Of/AF6P+EUf/oJf+Of/AF6y+tS/kf3o2+r0/wDn4vuZz2o38+mWT3lsVEseNu5cjk46Vl2ninU9UuBaXTQmJgSdkeDxyOa7RvCLsMNfgj3i/wDr0g8HY6Xqj/tj/wDXqamKqSpypqG/mjSnQoxqRqOps+zOWur+fTLdru2KiWPG3cuRzx0rP/4TnW/79t/35/8Ar13J8Hk9b4H/ALZf/Xo/4Q0f8/if9+f/AK9ZYSvUw8HDkvrfc2xcKGIqKfPbS2zOG/4TnW/79t/35/8Ar1asfEF/rLvHeNEViG5dibeTxXaWvhK2iuA108N1EAcxPEMH9adqXhi1kWP+zLe0tGBO8qu3cO3QV0V8S62HlFxs38zmoUoUcRGSldd7W7nH3Gp3OmGE2xQGeQRPuXPyn0rUIwcVbfwfdSbfMktW2nK5JOD69Kk/4RfUP+fqD/vs/wCFc2HrypUlBwZ04mlTrVXNTRQqOaFLiCSGQZSRSrD2IrT/AOEW1H/n5h/76b/Crem+Hbi3vVku3hmhAIKZJye3UV0LFtu3IzmlhopNqaZzMGnolktvO7TtuLySZKF2PU8GknsHnnjJnHkxyJIqmPLoVxwrZ4Bxz+PrXf8A9m2P/PpF/wB80f2bY/8APpF/3zW/tonNyM83j0GOC1+zwzCNZIRFcFYwDKM5z7HBI/H2qU6PCtwJIGMSbo2eMksGKNkdTxxkV6H/AGbY/wDPpF/3zTJtLspIXjWCKNmUgNt+6fWl7ePYFBnn9tpC20kTiZnMUpZcr/BtKqn0ANaNa/8Awij/APQS/wDHP/r0f8Io/wD0Ev8Axz/69Y/WpfyP70dH1en/AM/F9zOf1CV4NOuZYzh1ibB9OK4PpXrT+ETIhR9QVlYYKmPIP61B/wAIFanpLB/34H+NaRxjivgf3omWFg/+Xi+5nlmaM17anhrRFRVOk2bEAAnyRzS/8I3of/QIs/8AvyK6frcOxy+xkeI5ozXt3/CN6H/0CLP/AL8il/4RrRP+gPaf9+RR9bh2F7GR4hRXrmp+C7O7nV7S2tLZAuCvk9T68VT/AOEBX1tP+/JrGWOs7KD/AAOiOFi1dzS+85vSf+QXb/7v9TWBrH/IVn+o/kK9ITwbPGoRLqBVHRQhAFZ8Ol6dbX7T31utwkbum024PnMrBCFyezEdcV5+FlOniJVHHR3/ABZ6OKdKph401PVW79EL4G/5Ftf+u8n9K6rTn2Xqf7WRWes2nwSx2NpaGzcl90HlhNpG0nOOOQwII606yvkmnO1JI2iKsRIu04PQ/jg+9e/GSnC/c+fa5ZHVUUUVzHSFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFRzv5cEj+ik1JVTU322bD+8QKcVdibsjFp8cLXCTQK+xpImUN6e9Mqa2lWGXc2cYxxW9aPNTaOenLlmmZp8L3QGTqmB6kN/jSf8I1P/0F1/M/41b8Q30DaTJD826QgLkdcHNchgelfL14woz5XH8T6jDSq14c/Pb5I6aPw5OkiOdWUhWBIyeefrXR+YhPDqSewYV5tgelW9KKx6tauRwsoJpUq6T5Yx38x18LKUeac9vI7LVdNGqWywmYxbX3ZC57Vk/8Igv/AD/t/wB+/wD69bf2+H/a/Kj7fD/tflXoSwbm7yieXDGSprljLQxP+EQX/n/b/v3/APXpr+FIYhuk1LYM4yygf1rd+3w/7X5Vma8P7SsUhgHzLIGO7gYwf8azlgrRbUPzNqeOnKSUp2XyIbHRbSyvYrn+1Y38s52kqM/rW59rtf8An5h/7+D/ABrhLjTpbQKZjGoY4GDn+lQeWv8AfT9f8K5faSovl5LfM7Xh417T57/I9C+12v8Az8w/9/B/jSrc27sFS4iZj0AcEmvPPLX++n6/4Vc0cJFq9tIXUhXzgZz0PtVRxEpSUbb+ZnPBRjFy5tvI7uq2o2X9oWT2xkMe4g7gM4waX7fD/tflR9vh/wBr8q9B0JtWcTyo1oxaaZif8Igv/P8At/37/wDr0f8ACIL/AM/7/wDfv/69bf2+H/a/KgX8II+9+VY/UV/J+Z0/2hU/n/I58+GrQEg6wgI6g7f/AIqnwaBaQzxy/wBrxt5bhsZXnB+tY+oWUkNw8khjVZXYrznvn096q+Wv99P1/wAK8+SUJWlCz9T1YKVSN1Uun5I9C+2Wv/PzD/38FH2u1/5+Yf8Av4P8a898tf76fr/hT4bUzyrFG0Zdug5H9K1WJm3ZR/E53gYRV3LT0PQ0dZFDIysp6FTkUtZWkSLY6ZDbzD50znbyOpNXft8P+1+VejGlVaTcTypTpqTSZlXnhhbu8luPtjJ5rbtoTOP1qH/hEF/5/wBv+/f/ANetv7fD/tflR9vh/wBr8qyeCu78husfNKyn+RhSeFYYseZqezPTcoGf1pn/AAjdn/0GI/8Ax3/4qneKZ4riO2VWwVZj8w+lc95a/wB9P1/wrgrRjTm48v4np0JVatNT59/JHa6VFa6ZaG3F/FLly24uo6/jV37Xa/8APzD/AN/B/jXnvlr/AH0/X/Cnw2jXEoiiaMueg5H9KqFeWkYx/Eipg4u85z/A9AS4gkbbHPG7eiuCakrk9G0+aw1NLiYJsVWB2nJ5FdJ9vh/2vyrvp060leUWjy6zpQlaErosVkapoA1O7+0G6aL5Au0Jnp+NX/t8P+1+VH2+H/a/KqlhpzVpRJp4hU3zRlqYn/CIL/z/ALf9+/8A69Rv4Yto2Kvqyow6hgAf51v/AG+H/a/KuT8QR79Ue4yoSUDbnrwADXJXwypQ5uQ78Nip1p8nP+CLn/CN2f8A0GI//Hf/AIqtHSLK00oykajFL5gHVlGMfjXH+Wv99P1/wo8tf76fr/hXJGpGLuo/id06M5x5ZTdvQ9C+12v/AD8w/wDfwf40+OaKXPlyI+Ou1gcV57Dam4lEUbRlz0HI/pXSeH4W0xbgXAA8wrt2HPTNdtGVWq9I6dzzsRRpUY6z17HQEZUj1Fc3/wAItd/9BP8ARv8AGtz7fD/tflR9vh/2vyronhZT+KLOWnivZ35WYZ8LXQ5OqYH0b/Gm/wDCNT/9BdfzP+Namp3kT6XdKN2TEw6e1cPgelcGIpxoNJx382enhalTERbU9vJHfaZb/YLJbeS5WZlJO/d1yfc1Rfw9ZlriSG6EUtyxeR8KcnzBIPyIx7jr0FcfgelGB6VMcXyqyj+JUsv5ndy/D/gnV3ulyLew3i3xa4+YvIYgQ4IUYAzwAFH61HZWbWiSB5/PaRtzSFNrMfU889h7AVJYn/iVWiYIKR8gj1Oamr6bD3dKLZ81XSjUlFdDoLV/Mto29VFS1S0t91pt/usRV2s5KzNYu6CiiipGFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFNZ1T7zBc+pxSedF/z0T/voUrgPopnnRf8APRP++hR50X/PRP8AvoUXQD6zNXf/AFUf1JrQ86L/AJ6J/wB9CsfUpVkuyAwIVQODWlO3MZ1H7pVopNw9R+dG4eo/Oum6OczNe/49of8Af/pWHW54gDnTxJEu8xuCQOeDxXMm4mHWLH1Br5/H4WpUruUdtD6HL8XSp0FCW+paqxp//IQt/wDfFZv2mX/nmPyNXdHkebVIQwVFUliTx0rmpYKqqkW7brqddXHUXTklfZ9DraKQOp5DKR7GjcPUfnX1N0fJi0Um4eo/OjcPUfnRdAZWv/6qD/eP8qxa2vEIc2UckS7yj8gc8GubNxMODFg+4NfP47C1Kldyjtp+R9FgMZSp0FCT11/MtVa0z/kJQf739Ky/tMv/ADzH5Gr+iSPNqce8KioCxJ4rno4OrGrFu2jXU6a2NoypSSvqn0OropNy/wB4fnRuHqPzr6i6PlBaKTcPUfnRuHqPzougMjX/ALsH1b+lY9bHiIP9miliXftfDAc4BH/1q503MoODHg/Q189jsLUqV5Sjs7fkfR4HGUqdCMJbq/5lqrelf8hKH6n+RrK+0y/88x+Rq/okskuqR7gqqoLEnjt/9esKGDqxqxk7aNdTor42jKlKKvqn08jq6KTcPUfnRuHqPzr6i6PlBaKTcPUfnRuHqPzougMfX/vW/wBG/pWRWt4jEghhmjXftYqwHOM//qrA8+f/AJ4n/vk187jcJVqV5Sjs7fkfR4LG0aeHjCT1V/zLNXdI/wCQlH9D/Ksnz5/+eJ/75NaOhNNJqalk2KikkkEe1Z4fB1Y1YyfRrqa4jHUZ0ZRT1aZ1FFJuX+8Pzo3D1H519NdHy4tFJuHqPzo3D1H50XQC1ja/96D6N/Stjcv94fnWJ4jYiGGaIq+1irAHOM//AKq48bB1KEox30/M7cDUVPERnLbX8jLoqr9pl/55j8jR9pl/55j8jXz31Gt5fefR/X6Pn9xraR/yEo/o38q6SuX0F5pdTUlNqKrEsQfpXT7h6j8693LqUqVFxl3/AMjwMyrQrVlKHb/MWik3D1H50bh6j869C6POIb7/AI8J/wDrma5aupvcvYzqmCxjOBn2rjftE3/PL9DXi5lQlVnFxtt3PcyvEQpQkpd+xZrNa7MXnSNM7TozfuP4QoPBxj05z3qz583/ADy/Q0qzXDsFWHJJwODXmxwlTy+9HpyxlLfVfJm617NPosT22/P2pIAYn2l0DgHDHpkd6r3F9qdu6W7ysJIyA7L827Ow+nYEjI68mugiAiiSPcDsULnPoKduH94fnX1MVaKVz5OUk5Nlbw/r1zd6i1nFFEEaQEuQeE2semThuAOfXp2qW71a8tNdvCspkSFyBBvz8vkq2dmMhd2fmz7Yq9p0ypeLlwAwIPNbPnRf89E/76FY1LKRrTehgXHiK58yX7HDDLFGThzuO8BkXgj/AHyc+1EfiG6N61s6W4eJ1Rk+YNKTK6EoOwAXd3/rW/50X/PRP++hUa/ZlmeZTGJHUKzZGSBnA/U/nWd0aE9FM86L/non/fQo86L/AJ6J/wB9Ci6AfRTPOi/56J/30KVXV87WDY9Dmi4DqKKKYBRRRQAUUUUAFFFFAGP4i/1MH++f5Vg4HpW94i/1MH++f5VhV59f42c1T4hjuseMozZ/urmmeen/ADyl/wC/ZqaisGmNOCWq/Eh89P8AnlL/AN+zTGvoIztbep9ClTvIsa7mOB9M1lXp825LoGZcDnaaxqzlBaHfg8PTxE7STS73/wCAXRqFsTjLf981L9oX/nnL/wB+zWOiMHUlGwCOxrY+1w/3z/3yf8KmnVcr8zsa4vB06LXs4uV/67B9oX/nnL/37NVriOO5kDt56kDHEdTm8tx1lA+oNH222/57D8jVy5ZKzaOekqtKXNCnJP8AryKf2OH1uP8Av3R9jhPe4/79Vd+1Q/3z/wB8n/Cj7VD/AHz/AN8n/Co9lT8v6+Z0fW8X2l/XyEtFSOPykEmBzl1xU9Q/aof75/75P+FSI6yLuU5H0xW8eW1kzzq0ajk5yi1fuOpjyCMgFXOf7q5p9RtcRIxVmII/2TTbSRnTi5PRX9BPtC/885f+/ZqlcyWlxLvaWRTjGAlXftcP98/98n/Csd0YuxCNgk9jXLWloloz2cvoJzcmnFr+uqJ1itHbas0zE9glPNlCe9x/36qKz/d3SO6sqjOTtNaRu4AMmTA91NTTjCSvKyN8VVr0qijTcpK39dAE6gAeXLwP+eZpftC/885f+/Zpv262/wCew/I0ou4D0kyPZTXTzL+ZHkOjLd05fj/kL9oX/nnL/wB+zR9oX/nnL/37NJ9qh/vn/vk/4UouoScbz/3yaOZd0T7J/wDPt/j/AJEo9elUZYYZZWkZbjLHnCVepkkyRY3tjPTgmnOKa1Fh6s6cvcvd9ij9kt/S5/74pm2xR+Xmyp6Favfaof75/wC+T/hWVOGeeRlViCxIO01y1FGKvGzPZwkq1aTVRyiv68jSW/t3bau8k9AEqT7Qv/POX/v2ay7TMdyjurBQeTtNaf2qH++f++T/AIVrTqOSvJ2OLF4SFGajTi5K39dBftC/885f+/Zo+0L/AM85f+/ZpPtUP98/98n/AAo+1Q/3z/3yf8K05l/Mjk9k/wDn2/x/yGyyiSJ0CSgsMZ8s1R+yN/fk/wC/Rq+b23HBlAPuDR9ttv8AnsPyNZzjCb95o66FTEUI2pwdn5f8AofZG/vyf9+jQbMn+OT/AL9GtJbiJ2CqxJPT5TUlJUIPYuWZYiLtJNfd/kQQOFRItsmQMZKECp6KY80cZAdsE+xNbr3VqeZK9SXurX7xs1zFb48wkbumBmov7Rtv7zf981W1B1mMfl5bAOflNU9j/wBxvyrlqV5KTUdj2sNl1GpSUql0/wCvI2Rco65CSkEcERmqX2KEd7j/AL9VaguIkt41ZiCFAI2mn/a4B1cj/gJrVqM0nJo5ISrUJSjSjL+vkUvscPrcf9+6VbGJmC7pxnuY8Crf262/57D8jSi8tz0kz9Aan2dLuv6+Zq8VjLbS+7/gDoYhBEIwxYDuakqH7VD/AHz/AN8n/CnJPFIwVWJJ/wBk1unFaJnmTp1pNzlF+eghnUH/AFcv/fs0faF/55y/9+zUtFFn3FzU/wCX8f8AgEJnVlIMcuCMf6s1U+yW/wDduf8AvitGiplT5tzaliXSvyXV/P8A4BnfZLf+7c/98VJBHDbuXRbgkjHKVdqI3MIJBY5H+yan2cYu+ht9arVU46tev/AD7Qv/ADzl/wC/Zo+0L/zzl/79mm/bbb/nsPyNAvbc8CUE+wNVzL+ZGXsZf8+pfj/kD3caLudZFHqUNM/tC19W/wC+ajvpkltisZLNuHG01nbH/uN+VYVK0ouy1PRwuAo1afNUTT/ryNhbqJ13IkjD1CGl89P+eUv/AH7NQWU0cVsFclWyeNpqf7VD/fP/AHyf8K2jO6TbOGrQUKjjGDaT/roHnp/zyl/79mpEIddwUj2YYNR/aof75/75P+FPSVJQShzjrwRVppvc5502o35Gv69B2B6VueHfu3H1X+tYlbfh37tx9V/rXRR/iIzp/EbVFFFegdIVDdXC2lpNcMjOsSFyqDJOBnAqamTR+dC8ZZ03qRuRsMPcH1oAp2urQTW4klZISRuwJFcEZwCCuQRmmW+v6fcQpJ5xRnxiMqS3OemBz0PI44qP/hHrYksbi43O26VgyjzPmDc4GByo6Y7+tNbw3avCImuLllVdiZZSUXJOBx6nr1GBg8UAWotZsZWKLK28eZ8pjYHCHDHGOmeM00a5pxZlE5+VA+fLbHLFQOnXIIx14pjaFbMsqmWfEiuv3xlQzbjjj19c9cVEPDNkIvLDy7c7sHaRu3s4ONuOCzcYxg9KAGa3NFcWdtNC4kjckqyngjFYtbOswJbWNrBH91DgcAdvasavPr/GzmqfEMaaJG2tIqkdiab9pg/57J/31TyUB+YqD7kUbo/7yfmK59e5aULbP+vkM+0wf89k/wC+qX7VB/z3T/vqnbo/7yfmKN0f95PzFF33Han/ACv7/wDgDftUH/PdP++qPtMP/PdP++qjumj+yy4ZM7exFY9YVK0oOx6GEwFPEQctVb+uxZ1B1kudysGG0cg1XU/MPqKv6YUEcm4qPmHU1e3R/wB5PzFZql7T377nZPG/Vf3Chfl0vf8A4A0XMLEATISeg3VJk03dH/eT8xRvT++v/fQrsT7ngSivsp/18h2T60U3en99f++hSgg9CD9DTuRytdBaM0UUCDJ9aMn1oopgMa4iVirTKCOoLVWvp4ntGVZVY5HANWztHLbR9aTdH/eT8xWck2mrnTRlCE4zUW7ef/AMGtLT5o47cq8iqdx4JxVzdH/eT8xRuj/vJ+YrGnR5JXTPQxOPWIp8koNfP/gDftUH/PdP++qPtUH/AD3T/vqnbo/7yfmKN0f95PzFb3fc8y1P+V/f/wAAZ9pg/wCeyf8AfVL9pg/57J/31WI+N7fU1Y08qLsbiANp61zRxEnK1j2KuVU4U3O7dlc1FuInYKsqsT0Aan5PrTQ0eeGTPsRTq61c8OaSeit6hk+tGT60UUyQyfWgttBJbAHUmkJA6kD6mk3p/fX8xSuNRb6GTfur3TMrBhgcg1XHUfWt7dH/AHk/MUbo/wC8n5iuSWH5ne57lLM/Z01BU3orb/8AAG/aoP8Anun/AH1SfaYP+eyf99U/dH/eT8xRuj/vJ+Yrp17nk2h/K/v/AOAM+0wf89k/76pftMH/AD2T/vqnbo/7yfmKN0f95PzFGvcLQ/lf3/8AAG/aoP8Anun/AH1R9qg/57p/31Tt0f8AeT8xRuj/ALyfmKLvuLlp/wAr+/8A4A37VB/z3T/vqorm4ha2kUTKSV4Aap90f95PzFZ2plS8e0qeD0rOrJxg2deDowqV4xs11+7XsUqv6bLHGsm+RVyRjJxWfW7CUMSY2k7RnFcuHjeV10PYzSoo0eVq6f6ALmFiAJkJPQbqkzSYHoPypa9BX6nzEuX7KCiiigkKKQsq/eYD6mk3p/fX/voUXHyvsOphuIkba0ygjqC1LvT++v8A30KN8f8AeT8xSb7FRivtJmHIQZXIOQWNTWDql0rMwUYPJNa26P8AvJ+Yo3R/3k/MVzKhaXNc9qpmfPTdN03qrb/8Ab9qg/57p/31R9qg/wCe6f8AfVO3R/3k/MUbo/7yfmK6LvueRy0/5X9//AG/aof+e6f99Ufaof8Anun/AH1WLLjznx/eNTWGBdrnAGD1+lcyxEnK1j2J5VThSdS70VzU+1Qf890/76pySJICUcMB1wc0bo/7yfmKUMp+6VP0NdSb7njSUbaJ/wBfIWtvw7924+q/1rErb8O/duPqv9a3o/xETT+I2qKKK9A6QooooAKKKKACiiigDH8Rf6mD/fP8qwq6u+sEvlRXdlCHI21m3GiQRJxNLk/TiuSrSlKV0Yyg3IxGjjc5ZFY+pGaztTREePairkHoMVuf2E3/AEEp/wDvkU1/DqyY330zY6ZRTXHUw9Wcbcv5f5no4TloVVN1LpdNf8jl8Ctm3hiNtGTEhJUclRV3/hGov+fyT/v2tPGglQANRnAHQBRWdLCVYO7j+X+Z1Y2vDERSjO1vX/IqeRD/AM8k/wC+RR5MX/PJP++RVz+wm/6CU/8A3yKnttGRW2yXcsm48EgDFdCoVG/h/I8udOSV1Uv95meTD/zyT/vkUeRD/wA8k/75FdF/wj1v/wA9pP0o/wCEet/+e0n6VX1eXYx/e9/xOd8iH/nkn/fIrIvFVbuQBQAD0ArrrvRYhmOO4lRv7wA4qi3htGJZr2Uk9SY1rCthaklaK/I9LAVVRk51JeVtTm4gDNGCAQWFbqoqZCqFHoBiph4ajBBF5ICP+ma1J/YTf9BKf/vkUqWGrQveP5f5l46cMS1yztb1/wAitRVn+wm/6CU//fIo/sJv+glP/wB8itvZVf5fxX+Z5/1aH/Pxfc/8itRWtaaLC4CPcSswH3jjmrP/AAj1v/z2k/Sr9hPsc7ptM55kVxhlDD3GaTyIf+eSf98iui/4R+3H/LaX9KzrjRlkYeXeTRAdcAHNJ0J72uaU4zvbmsvn+hneRD/zyT/vkVlX6qt2wVQBgcAV0P8AYTf9BKf/AL5FMbw4jnc17Kx9TGtc9XDVZxso/l/melg5xoVOaVS6t5/5HNRgGROB94VuGCH/AJ5J/wB8irA8NRg5F5Jn/rmtSf2E3/QSn/75FKlhasL3j+X+ZpjasMQ4uE7W9f8AIp+TF/zyT/vkUeTF/wA8k/75FXP7Cb/oIz/98itGDRIJUz50g/KuhUJveNvuPMnCcfhnf7/1MIQxA5ESAj/ZFPrf/wCEet/+e0n6UjaBbqpPnScD2qvq810MXGctzBoq3Joe6RmW/nQE8KFHFN/sJv8AoJT/APfIqPZVf5fxX+ZssPG3xr7n/kVWRXGGUMPQjNUdSjjSFCqKp3dhitj+wm/6CU//AHyKa3h4OMPfzMB6opqJ0Ksotcv5f5nVhoxo1IydTRdNf8jl8Cteziia0jLRoSR1Kir/APwjUX/P5J/37WpoNDWFhm8mdAPubQBWVLB1YSu4/kdmOxMK9O0JWa16/wCRR8iH/nkn/fIo8iH/AJ5J/wB8it+LQreSMN50n6U//hHrf/ntJ+ldX1eXY8X973/E53yIf+eSf98ijyIf+eSf98it+XQYEjZvOlzj2rM/sJv+glP/AN8ik6E1tG/3GkIzl8U7ff8AoU/Ih/55J/3yKxZwBcSAAABjXTf2E3/QSn/75FRnw3GSSbyQk9T5a1z1cLVmlaP5f5npYKpHDyblO9/X/IwLJVa7QMoI54I9q1/Jh/55J/3yKsr4cRCGW9lUjuI1p/8AYTf9BKf/AL5FOlhqsFZx/L/MnGTjXmpRnbTz/wAin5MX/PJP++RSrGiElUVSfQYrRg0dIwRJdSykngkAYq8ugW7KG86Tke1dCw897HmTjO7XNdGFRW//AMI9b/8APaT9Kq3uhxKoSO5lRjzuABpuhUtsRGk27PQyqKs/2E3/AEEp/wDvkUf2E3/QSn/75FR7Kr/L+K/zN/q0P+fi+5/5FRkR8b0VsdMjNY12qrdyAKAAegFdJ/YTf9BKf/vkUxvDaMSzXspJ6kxrWNXDVZrSP5f5nfgpww025Turef8Akc7aqpuogQCC3QitnyIf+eSf98irI8NxqQVvZQR0IjWr1to8R2xvcSse7EDmnRwlSKakvyJzCsq0lKnL8zI8iH/nkn/fIo8iH/nkn/fIrov+Eet/+e0n6Uf8I9b/APPaT9K3+ry7Hm/ve/4nO+RD/wA8k/75FHkQ/wDPJP8AvkVp3eiKZNsd5NGF64AOag/sJv8AoJT/APfIqXQqJ/D+RtGnJq7qW+//ACMPU0RGj2qFyD0GKomuofw8smN99M2OmUU03/hGov8An8k/79rXJPB1pSbUfy/zPaw2LpUqShKV2vX/ACKkUMRhQmJCdo/hFSLHGhyqKp9QMVbGgsBgajOAP9kUDQmBBOozkZ6bRzXUqNRfZ/L/ADPInT5m/wB5+f8AkVq2/Dv3bj6r/WmwaLBNn97IMfStGx0+OwDhHZt+M7vaumlSlGabOWEGnct0UUV1mwUUUUAFFFFABRRRQAVSvf8AWL9Ku1WvFzGG9DQBSoqhrlxLa6TLNDIY3DRjcGC4BdQeSCBwTzislNVuBCWuLyUGJMxrE0ebgh2BwSMSYAUcYznOOaAOlorHsdTnn1qRHWUWk5dLYtHhMx9SG77vmP8AwGqNtrV1FcXHm3CyAvIiIzKwVhMVGcY2Db6nnrn1AOmoHUVg6Pq9xqWoqzErBLEziMgfL8kJAz9Xb866KFPMkC9u9AGlRRRQBmTf69/96mVPdriXPrUFABRRRQAUUUUATWn/AB8D6GtCqdnHli57cCrlADJf9U/+6azK1SMgisx12uR6GgBtFFFABRRRQAVbsf4/wqpV60j2R7u7UAWKiuf+Pd/pUtNddyMPUUAZdFKRgkUlABRRRQAUUUUAXbL/AFR/3qs1Fbp5cQHc8mpaAK95/qP+BCqNaU67omHtWbQAUUUUAFFFFABWjbf8e6fSs8DJAHetONdkar6CgB1Z93/x8N9BWhVO9X5lb1oAq0UUUAFFFFABTov9an+8KbU1tHvlB7LzQBoUUUUAZTffb60lS3K7Zm9DUVABRRRQAUUUUAWLL/Wt/u1eqrZJgF/XgVaoAKKKKACiiigAooooAKKKKACkZQylSMg0tFAGZNEY2IZflPSmYHHA46e1ackayLtYVVks2H3Dke9AFakwOeBz1461P9kl9B+dKLSQnnAoAgxk8Dmr9rCY1JYcmiK2SPBPLVPQAUUUUARTxCVCMcjpWeQVODwRWrUUtukvJ4PrQBnUVYazkB+XBFN+yS+g/OgCGnIjOwVRyanSzcn5iAKsxwpEPlHPrQAsSeXGF9KfRRQAVVu4cjeo571aooAyaKvSWiucqdpqA2kuegoAgoqb7JL6D86kjsz/AMtDj2FAEMMTSvx0HU1ogYGBSIiou1RgU6gAooooAp3UBzvReO9Va1TzxVeSzU5KHB9KAKVFT/ZJfQUn2SX0H50AQ1NbwmRwxHyipY7PBzIc+wq0qhQFUYAoAWiiigAqjcwlGLKvymr1IQGBB5BoAyqKtyWfeM/gai+yS+g/OgCGip/skvoPzqaOzVeX5NADLWE7vMYcdquUgGBgUtABTJIxIhUj6U+igDLdCjFWGDTa0pYUlHzDn1qq9m4PykEUAV6Km+yS+g/OnLZyE84AoAgAJOByav28XlR89T1pYrdIjkcn1NS0AFFFFAENzF5kfAyw6VQIIOCMEVq1DLbJIc9DQBn0VObSQHjBFJ9kl9B+dAENPjjaVsKPrUyWbEjecCrUcaxjCjFACouxQo7U6iigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD//Z)

**6.2 Thermal Consideration**

TBD

 

**7 Design Flow**
![image](https://github.com/user-attachments/assets/0e18dec5-223a-4f74-83d7-0b57eb1ffd6d)


**7.1 Architecture**

SoC partitioning is a decomposition and reconstruction exploration of the original chip architecture, extending from the original x and y axes to the y direction, exploring design possibilities, improving system performance, expanding to larger spaces, and reducing the design cost and yield of the SoC itself.

Firstly, a SoC design (usually a netlist file) is divided into multiple small Dies for Modularization processing, laying the foundation for subsequent designs. Each Die is designed as an independent Chiplet for flexible layout planning and resource optimization. Subsequently, by adjusting the cost coefficient of the target function (design overhead), a new round of iterations can be performed, and the optimized layout can be gradually completed while the design overhead converges.
![image](https://github.com/user-attachments/assets/b3dd838e-225a-4891-82bc-e388d5bea8d9)

Chiplet modeling is a core step in system-level planning. The tool models each divided die to form an independent Chiplet module to ensure design repeatability and scalability. Each die can be physically planned and displayed as an IP in stacked design.

After system planning, physical design and testing can be integrated for collaborative design, and signal, power, power consumption, and timing analysis can be performed across Die levels.

Another indispensable component of Chiplet architecture design is the fabrication cost of the new system, which involves iterative convergence based on design indicators in partitioning, floorplanning, wiring, and optimization, and ultimately adapts to manufacturing costs, including wafer costs, packaging costs, bonding costs, test design costs, etc.
![image](https://github.com/user-attachments/assets/01598d79-8cd2-4f77-95fb-27064983244a)

**7.2 Front End and Verification**

**7.3 Raw Backend**

Floorplan is responsible for optimizing the layout of all Chiplets in 2.5D/3D integrated circuits, ensuring reasonable resource allocation, and preparing for subsequent wiring and simulation.

Multi-chip integrated system is a hybrid integration of multiple homogeneous or heterogeneous die chips at the packaging level. Compared with traditional chip integration, there are huge differences in quality assurance and testing requirements. Without testability and fault-tolerant design, the design and manufacturing problems of a large number of Bump interconnects and TSVs may become latent risks that undermine system stability and quality. Therefore, 3D DFT based on interconnect facilities is particularly critical.

In the early stage of system planning, DFT and FT (Fault tolerance) design resources are planned, and the hardware and interconnection resources required for testing and fault tolerance are allocated in the partitioning and system physical planning to complete the design preparation of 3D system stability, integrity, and collaborative thermal and stress management.

After obtaining a three-dimensional stacked floorplan with test completeness, interconnection relationship inspection, wiring, and optimization can be carried out to quickly complete the preliminary system structure. Designers can then further evaluate how to design the desired SoC architecture based on the generated multiple structures.

Check the consistency of the physical connection relationship and logical connection relationship for Bump bump interconnection planning. If there are bump misalignment, bump misalignment, or incorrect bump connection problems.

After checking the Bump interconnection, quickly enter the pre-wiring and optimization. The tool performs global wiring and detailed wiring on the stacked structure to ensure that the signal connection between chiplets can meet electrical requirements and automatically iteratively optimize the wiring effect.

**7.4 Backend and Package Iteration**

**7.5 Verification**

After completing the system-level planning, we enter an early analysis of system performance, which is a multi-level co-design and simulation.
![image](https://github.com/user-attachments/assets/e21422a1-9e30-4349-8a1c-d4006e308ef2)


In the preliminary planning of the multi-chip integrated system, the interconnection wiring still needs to check the robustness of the wiring based on factors such as manufacturing process differences for the final required performance, especially in high-bandwidth and high-power consumption scenarios. In the early analysis of the system, the tool extracts parasitic parameters from the system model, especially for the structure of power lines and signal lines interconnected across Die, to complete the inspection of the overall winding constraints and ensure the integrity and reliability of the structure.

Note: some figures are copyed from www

 

 

 

 
