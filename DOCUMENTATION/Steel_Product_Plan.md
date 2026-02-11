- *Plan Still needs refinement*

Sourcing and Partnership Strategy for Steel Project
1. Consolidated Partner Directory
This directory categorizes vetted suppliers capable of executing the "Steel" technical vision. The selection prioritizes manufacturers with proven experience in NTAG 424 DNA integration, ferrite shielding for metal substrates, and miniaturized epoxy encapsulation.

A. Metal NFC Card Manufacturers (Primary)
These suppliers have verified capabilities in producing hybrid metal cards (PVC/Metal composite or CNC stainless steel) and support the specific NXP chips required.

Supplier Name	Specialization	Capability Mapping
Shenzhen Chuangxinjia (CXJ Card) 
Alibaba
Hybrid & CNC Metal Cards	• Best Fit for Full Vision: Experienced in CNC-milled cavities for chips.
• Supports NTAG 424 DNA with custom key injection.
• Verified export history to North America/Europe.
Shenzhen Mytopband 
Alibaba
Premium Metal Finishes	• Specializes in 1mm thick matte black metal cards.
• Strong aesthetic capabilities for the "Steel" brand feel.
• High delivery rate (86.2%) and 5.0 review score.
Guangdong Xinye Intelligent Label 
Alibaba
Anti-Metal Solutions	• Critical for Signal Integrity: Experts in ferrite magnetic layers to prevent signal dampening on stainless steel.
• Large-scale capacity (Rev >$100M) for future growth.
B. Wearable Module & Component Supply Chain
This category covers the supply chain for the 30mm × 20mm × 8mm waterproof core module.

Component / Service	Recommended Supplier	Role & Specifications
PCBA & Potting	Shenzhen Kingsheng Tech	• Manufacturing Partner: Specializes in miniaturized wearable PCBA.
• Capable of SMT assembly for nRF52832 + NTAG.
• Can handle epoxy potting for IP67/IP68 waterproofing.
NTAG 424 DNA	Mouser / Digikey / Avnet	• Critical IC: NT4H2421G0DUD/02Z (50pF input capacitance).
• 
accio
 for prototyping batches.
Coin Cell Battery	Huizhou Winpow 
accio
• Power Source: CR2032 Lithium Coin Cells (3V).
• Direct manufacturer for bulk wholesale (<$0.10/unit).
Epoxy Tags (Alt)	Zhuhai Found Smart 
accio
• Alternative Form Factor: Ready-made waterproof epoxy NFC tags if custom potting has high NRE (Non-Recurring Engineering) costs initially.
2. Strategic Outreach Framework
Use this technical questionnaire to vet the "Technically Solvable" aspects of the project during initial contact. This framework ensures suppliers understand the architectural constraints immediately.

Part 1: Metal Card Signal Integrity (For CXJ & Mytopband)
Shielding: "What is the standard ferrite sheet thickness you use for stainless steel cards? Can you accommodate a 0.2mm - 0.3mm ferrite layer between the NTAG 424 DNA antenna and the metal body to ensure <4cm read range?"
Cavity Milling: "Do you CNC mill a pocket for the chip/antenna assembly, or do you rely on a full laminate (sandwich) structure? We require a flush finish where the antenna is invisible."
Tuning: "Do you have experience tuning 13.56 MHz antennas specifically for 50pF input capacitance chips (NTAG 424 DNA) when mounted on 316L stainless steel?"
Part 2: Wearable Encapsulation (For Kingsheng/PCBasic)
Potting Compound: "For a 30mm x 20mm module, what epoxy resin do you recommend to ensure RF transparency for Bluetooth (2.4GHz) and NFC (13.56MHz) while maintaining IP68 waterproofing?"
Thermal Management: "Will the curing process of your standard potting compound affect the pre-programmed NTAG 424 DNA data retention (approx. 150°C limit)?"
Mechanical Pins: "Can you insert-mold quick-release pins (metal) directly into the epoxy body, or must they be part of the PCB assembly?"
3. Prototyping & Testing Roadmap
This phased approach moves from off-the-shelf components to custom manufacturing, mitigating the risk of high tooling costs early on.

Phase 1: Signal & Logic Validation (Weeks 1-4)
Objective: Validate SDM URL generation and OOB Bluetooth pairing.
Hardware:
Standard PVC NTAG 424 DNA cards 
accio
.
Nordic nRF52832 Development Kit (DK).
Action: Build the firmware to handle the "read-only" architecture. Verify Supabase backend integration using standard PVC tags.
Phase 2: Material Engineering Pilot (Weeks 5-8)
Objective: Solve the "NFC through Metal" challenge.
Hardware:
Order "Dummy" metal cards with CNC cavities from CXJ Card.
Source "Anti-metal" ferrite stickers 
accio
.
Action: Manually assemble NTAG inlays into metal cavities with varying ferrite thicknesses. Test read range on iPhone vs. Android. Decision Point: If stainless steel range is <2cm, switch to Titanium or Composite construction (Metal border + Plastic window).
Phase 3: Wearable Miniaturization (Weeks 9-12)
Objective: Validated Potted Form Factor.
Hardware:
Custom PCBA design with Kingsheng.
CR2032 battery holders.
Action: Produce a small batch (50 units) of un-potted PCBAs to test Bluetooth range. Once confirmed, perform potting trials to ensure the epoxy doesn't detune the NFC antenna.
4. Supply Chain Risk & MOQ Analysis
Component	MOQ Risk	Lead Time Risk	Mitigation Strategy
NTAG 424 DNA	Low (1 unit @ Distributors)	Medium (Specialty Chip)	Keep a buffer stock of 5,000 units. This is a high-security chip and specialized variants (TT/DNA) often go on allocation.
nRF52832 SoC	Medium (3k Reel)	Low (Widely Used)	For Phase 1-2, buy cut-tape from Mouser 
accio
 at a premium. Move to reels only after PCBA validation.
Custom Metal Cards	High (100-500 units)	High (CNC + Etching)	Negotiate a paid "Sampling Run" with CXJ Card. Do not commit to 1,000+ units until the ferrite shielding performance is proven.
Wearable Potting	High (Custom Tooling)	Medium	Use 3D printed molds for the first 50 prototypes before cutting steel injection molds for the epoxy process.
Key Architectural Decision Support
Remote Updates: Your decision to keep the card "dumb" (Store only Reference ID) is validated. It removes the need for complex write-access logic on the firmware side and relies on the robust Supabase backend.
Security: NTAG 424 DNA is the correct choice. Ensure you purchase the specific 50pF capacitance version (NT4H2421G0DUD) to match standard antenna tuning, as 17pF versions are typically for small inlays that may struggle in a metal environment.
