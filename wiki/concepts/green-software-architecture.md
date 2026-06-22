---
title: Green Software Architecture
aliases: [green software, sustainable software, sustainability, carbon-aware, SCI]
type: concept
domain: emerging
status: mature
tags: [emerging, sustainability, green, carbon, sci, carbon-aware, finops]
updated: 2026-06-22
sources:
  - https://greensoftware.foundation/articles/what-is-green-software
  - https://sci-guide.greensoftware.foundation/
  - https://electricitymaps.com/
  - https://github.com/Green-Software-Foundation/carbon-aware-sdk
  - https://www.cloudcarbonfootprint.org/
  - https://aws.amazon.com/aws-cost-management/aws-customer-carbon-footprint-tool/
---

# Green Software Architecture

> [!summary]
> Green software architecture treats carbon emissions as a first-class architectural quality alongside cost, latency, and reliability. It applies three principles — energy efficiency, hardware efficiency, and carbon awareness — to reduce the carbon intensity of software systems. The discipline overlaps strongly with cost optimisation (efficient systems are cheaper) and is gaining regulatory force through CSRD Scope 3 reporting obligations.

**Domain:** [[tier-3-watch|Emerging & Adjacent]]

## What it is

Software systems consume energy to run. That energy has a carbon cost that varies by the fuel mix of the electrical grid supplying the data centre. Architects make decisions every day that determine how much energy a system uses: choice of algorithm, data structure, caching strategy, cloud region, instance size, request batching, and deployment pattern all have direct energy consequences.

Green software architecture is the discipline of treating energy and carbon as measurable, optimisable properties alongside performance, cost, and reliability. It does not require trading off correctness or quality; in most cases, the same choices that reduce energy consumption — eliminating unnecessary computation, right-sizing hardware, caching results — also reduce cost and often improve performance.

The Green Software Foundation (GSF), founded in 2021 by Microsoft, Accenture, GitHub, Thoughtworks, and others, defines the framework and maintains the standards. The GSF's definition: software is green if it does more with less — consuming the minimum energy necessary to deliver its function, using hardware as efficiently as possible, and preferring times and places where the electricity grid is cleaner.

## Why it matters

**Regulatory force: CSRD Scope 3.** The EU Corporate Sustainability Reporting Directive (CSRD), effective for large companies from FY2024, requires disclosure of Scope 1 (direct), Scope 2 (purchased energy), and Scope 3 (value chain) emissions. Software-related emissions from cloud compute, developer laptops, and end-user devices fall under Scope 3. Organisations that cannot measure and report their software carbon footprint will fail CSRD audits. Cloud providers (AWS, Azure, GCP) publish Customer Carbon Footprint Tools that provide Scope 3 estimates for cloud usage.

**AI energy demand growth.** Data centre energy demand grew ~6% annually from 2015–2022 despite efficiency improvements. Generative AI workloads are accelerating this growth: training a frontier LLM uses ~300–1,000 MWh (comparable to a small town's monthly consumption); inference at scale is continuous. IEA's 2024 report projects data centre electricity use could double by 2026. Software architects who design AI systems without energy as a design parameter are building systems with growing environmental and reputational liability.

**Business case: cost and carbon are correlated.** Energy efficiency and cost efficiency point in the same direction. Idle compute wastes electricity and money; right-sizing reduces both; caching eliminates redundant computation and redundant API cost. The Green Software Foundation's research found that organisations with sustainability practices in software tend to have lower cloud costs on average. This makes green software a business performance argument, not just an ethics argument.

**Talent and procurement.** Engineering talent increasingly considers a company's sustainability posture in employment decisions. Enterprise procurement increasingly includes sustainability criteria for software vendors. Green software is becoming a competitive differentiator.

## Key concepts

### The three principles (Green Software Foundation)

**1. Energy efficiency.** Do more useful work per unit of energy. Algorithmic efficiency, choosing data structures that reduce computation, eliminating unnecessary processing, and caching results are all energy efficiency techniques. The measurement target: energy consumed per unit of useful work (per API call, per user, per transaction).

**2. Hardware efficiency.** Use hardware as fully as possible. An idle server consumes 40–60% of its full-load power. Right-sizing, bin-packing, and demand-matched auto-scaling maximise hardware utilisation. Avoid over-provisioning; avoid idle infrastructure. The measurement target: utilisation rate of provisioned hardware.

**3. Carbon awareness.** Prefer actions at times and places where the electricity grid is cleaner. The carbon intensity of electricity varies significantly by region and time: Pacific Northwest hydro runs at ~10 gCO₂eq/kWh; coal-heavy Midwest grids run at 600–700 gCO₂eq/kWh. At peak solar, midday carbon intensity drops by 40–60% even in moderate renewable regions. Time and location shifting flexible workloads to lower-carbon conditions reduces emissions without changing the work itself.

### Software Carbon Intensity (SCI) metric

The SCI is the standard measurement framework for software carbon impact, published by the Green Software Foundation and standardised as ISO 21031:2022.

**Formula:** `SCI = (E × I + M) / R`

| Component | Meaning |
|---|---|
| `E` | Energy consumed by the software (kWh) |
| `I` | Carbon intensity of the electricity grid (gCO₂eq / kWh) |
| `E × I` | Operational carbon (energy × carbon per kWh) |
| `M` | Embodied carbon — the manufacturing carbon of the hardware, amortised over its useful life |
| `R` | Functional unit — the unit of useful work (per user, per API call, per GB processed, per inference) |

SCI is an **intensity** metric, not an absolute one. It measures carbon per unit of work rather than total carbon. This means: (1) growing usage does not automatically worsen the SCI; (2) improvements to the software (better algorithms, caching) improve the SCI even if total usage grows; (3) SCI scores are comparable across software versions, making it useful for tracking progress.

**Practical SCI measurement:**
- `E` from cloud billing tools (AWS Customer Carbon Footprint Tool, Azure Emissions Impact Dashboard, GCP Carbon Footprint) or open-source tools (Cloud Carbon Footprint, Boavizta)
- `I` from Electricity Maps or WattTime (real-time and historical grid carbon intensity by region)
- `M` from hardware embodied carbon databases (Boavizta, manufacturer EPDs) or cloud provider estimates
- `R` from application metrics (request count, user sessions, data processed)

### Carbon-aware computing

**Time shifting.** Flexible workloads (ML training, batch data processing, CI/CD, model fine-tuning, backup jobs) can run when the grid is cleaner. The approach:
1. Fetch carbon intensity forecast from Electricity Maps or WattTime API
2. Identify the lowest-carbon window in the next N hours
3. Schedule the workload to start during that window

The GSF's **Carbon-Aware SDK** (open source, .NET / Python / JavaScript / Java) provides a unified API across multiple carbon intensity data providers, with built-in time-shift and location-shift logic. Azure Kubernetes Service has native carbon-aware scheduling annotations (pilot feature, 2025).

**Location shifting.** For workloads that can run in any cloud region, prefer regions with lower carbon intensity:

| Region type | Carbon intensity | Examples |
|---|---|---|
| Near-zero (hydro/nuclear/wind) | 10–50 gCO₂eq/kWh | Pacific Northwest, Nordics, Quebec, France |
| Low (mixed renewable) | 100–250 gCO₂eq/kWh | UK, Germany, California |
| Medium (gas-heavy) | 300–450 gCO₂eq/kWh | Texas, most US Midwest |
| High (coal-heavy) | 500–700 gCO₂eq/kWh | Poland, South Africa, parts of Asia |

For AI training in particular, location choice is a high-leverage carbon decision. Training the same model in Oregon (hydropower-heavy) vs. Virginia (gas-heavy) can differ by 3–5x in carbon intensity.

**Demand shaping.** Adjust what the software does based on current carbon intensity:
- Reduce video streaming quality during high-carbon periods (reduce GPU and network load)
- Defer non-urgent background sync until lower-carbon periods
- Show users a "low carbon mode" that reduces compute intensity with their consent
- Rate-limit or queue AI inference requests during carbon-intensity peaks, processing them in the next low-carbon window

### Efficient AI architecture

AI workloads are disproportionately energy-intensive. Several architectural choices reduce their carbon intensity:

**Model selection.** Smaller models that meet quality requirements have dramatically lower inference cost. A GPT-4-class model uses ~10× more compute per inference than a Haiku-class model. See [[model-selection-and-routing]] for the full cost-quality-latency triangle and cascading strategies that use smaller models for simple requests.

**Quantisation.** Converting FP32 model weights to INT8 reduces memory bandwidth by 4× and inference compute by approximately 4×, with minor quality loss for most tasks. INT4 quantisation reduces further with more quality impact. Apply quantisation to inference deployments where energy is a concern.

**Prompt caching.** Claude's and OpenAI's prompt caching features reuse computed key-value states for repeated prompt prefixes, reducing compute by 60–90% for cached tokens. For applications with consistent system prompts or large repeated contexts, caching is the single highest-leverage energy efficiency measure. See [[llm-application-architecture]].

**Batching inference.** GPU utilisation peaks during batched inference; individual requests underutilise GPU capacity. Batching 8–32 requests together can increase GPU utilisation from 20% to 80%, reducing per-inference energy cost by 3–4×.

**Right-sizing GPU instances.** An A100 GPU uses ~400W at full load. Over-provisioned GPU instances running at 10% utilisation waste 360W continuously. Fit models to the smallest GPU that provides adequate latency; use Spot instances for training to reduce both cost and peak demand on the grid.

### Overlap with FinOps

Green software and FinOps ([[cost-optimization-practice]]) converge on most of the same techniques. The same decisions that reduce energy consumption reduce cost:

| Practice | Carbon benefit | Cost benefit |
|---|---|---|
| Right-sizing instances | Less idle power | Lower compute cost |
| Spot / preemptible instances | Can time-shift to low-carbon windows | 60–80% lower price |
| Caching (prompt, CDN, query) | Eliminates redundant computation | Reduces API calls and compute |
| Auto-scaling to zero | No idle power draw | No idle cost |
| Serverless for intermittent work | Process exits between requests | Pay per invocation |
| Storage tiering | Cold storage uses less active energy | Cold tiers are cheaper |

The divergence: carbon-aware time/location shifting may increase cost (running in a low-carbon region may be more expensive; waiting for a low-carbon window may delay throughput). Optimising simultaneously for carbon and cost requires explicit trade-off decisions about how much cost premium is acceptable per unit of carbon reduction.

### Measurement tooling

| Tool | Type | What it measures |
|---|---|---|
| AWS Customer Carbon Footprint Tool | Cloud provider | Scope 3 AWS emissions by service and region |
| Azure Emissions Impact Dashboard | Cloud provider | Azure and M365 Scope 3 emissions |
| GCP Carbon Footprint | Cloud provider | GCP Scope 3 emissions by project |
| Cloud Carbon Footprint (open source) | Multi-cloud | Aggregates billing data; estimates emissions across AWS/Azure/GCP |
| Electricity Maps | Grid carbon intensity | Real-time and forecast gCO₂eq/kWh by grid region |
| WattTime | Grid carbon intensity | Real-time, forecast, and marginal carbon intensity |
| Boavizta Impact Framework | Embodied carbon | Hardware manufacturing carbon for SCI `M` component |
| GSF Carbon-Aware SDK | SDK | Fetch carbon intensity; time-shift and location-shift logic |

## Design decisions and trade-offs

**Carbon awareness vs. latency.** Time-shifting a workload to a low-carbon window reduces carbon but delays processing. The trade-off is acceptable for background batch work (training, ETL, model fine-tuning) and unacceptable for real-time user-facing requests. Design a two-tier workload classification: real-time (no time-shift possible; optimise through efficiency) and flexible (time-shiftable; apply carbon awareness).

**Location vs. latency and compliance.** Running in the lowest-carbon region is the maximum carbon lever, but it conflicts with data residency requirements (GDPR, financial regulation), user latency (a Pacific Northwest data centre for European users adds ~80 ms), and organisational cloud commitments. Map what is flexible (training, batch) vs. constrained (regulated data, latency-sensitive serving) and apply location shifting only to the flexible workloads.

**Embodied vs. operational carbon.** For some workloads, the embodied carbon of hardware (manufacturing) exceeds operational carbon (running energy). This is especially true for short-lived Lambda functions that run for milliseconds: the hardware's manufacturing carbon amortises across all workloads using it, so high utilisation of shared cloud hardware is a carbon efficiency advantage over dedicated hardware. The SCI framework captures this via the `M` term; consider embodied carbon when deciding between serverless (shared hardware, high utilisation) and dedicated instances.

**SCI vs. absolute carbon.** SCI is an intensity metric; an application can improve its SCI while growing its absolute carbon footprint. For sustainability reporting (CSRD), absolute Scope 3 emissions matter, not just intensity improvement. Track both: SCI for progress measurement; absolute cloud provider estimates for CSRD reporting.

## State of the art

**CSRD Scope 3 reporting** started for large EU companies (>500 employees) from FY2024 onwards. The cloud providers' carbon footprint tools are the primary data source for software Scope 3 reporting; the tools have improved significantly in granularity (per-service, per-region estimates).

**Carbon-aware Kubernetes scheduling** is in active development: Azure Kubernetes Service (AKS) piloted carbon-aware node scaling (scale down during high-carbon periods, pre-scale before low-carbon windows) in 2025. Kepler (open source, CNCF sandbox) instruments Kubernetes pods for real-time energy measurement.

**Efficient AI as mainstream concern.** The energy cost of AI inference has become a top-three concern in enterprise AI budgeting. Model distillation, quantisation (GGUF INT4/INT8 formats), and speculative decoding are now standard production techniques, driven by cost as much as by sustainability.

**Green Software Foundation** has 70+ member organisations. The SCI specification is an ISO standard (ISO 21031:2022). The Carbon-Aware SDK has integrations with Azure, GCP, and WattTime/Electricity Maps APIs.

> [!tip]
> The highest-leverage green software action for most organisations is measuring current carbon intensity (start with the cloud provider's tool) and identifying which large workloads (training jobs, ETL pipelines, CI/CD) are time-shiftable. Moving two or three large batch workloads to low-carbon windows can reduce their carbon by 40–60% with no algorithmic change. Start there before optimising algorithms.

## Pitfalls and anti-patterns

- **Greenwashing without measurement.** Claiming "we run on renewable energy" based on a cloud provider's Renewable Energy Credit (REC) purchase does not reduce actual grid-level carbon. Marginal carbon intensity (the carbon of the next unit of electricity added to the grid) is what determines the real impact. Use real-time carbon intensity data (Electricity Maps, WattTime) rather than REC-based accounting.
- **Optimising emissions without baseline.** Sustainability improvements without a measured baseline cannot be demonstrated. Establish an SCI baseline for significant workloads before attempting optimisation.
- **Treating green software as a constraint rather than a quality.** Green software techniques (caching, right-sizing, time-shifting) are performance and cost improvements with a carbon co-benefit. Framing them as environmental obligations creates organisational resistance; framing them as engineering excellence creates adoption.
- **Ignoring embodied carbon.** Frequently spinning up and tearing down compute hides the embodied carbon cost of the hardware manufacturing cycle. Long-running, well-utilised instances amortise embodied carbon more efficiently than many short-lived instances. Cloud shared infrastructure amortises embodied carbon across many tenants.
- **Carbon-aware time-shifting without SLO analysis.** Deferring a workload to a low-carbon window may violate an SLO or SLA if the window is too far in the future. Always define the maximum deferral window before applying time-shifting logic; failing an SLO to save carbon is rarely the right trade-off.
- **Applying SCI to the wrong functional unit.** An SCI expressed per API call for a batch processing system, or per user for a B2B platform, produces a metric that does not track the system's actual efficiency. Choose the functional unit that represents the value the system delivers.

## See also

- [[cost-optimization-practice]] — FinOps techniques that overlap with green software (right-sizing, Spot, tiered storage)
- [[cloud-cost-modeling]] — cloud pricing models and cost levers that align with energy efficiency decisions
- [[model-selection-and-routing]] — smaller model selection and cascades as AI energy efficiency levers
- [[llm-application-architecture]] — prompt caching and batching as inference energy optimisation
- [[cloud-native-patterns]] — serverless and auto-scaling patterns that improve hardware utilisation
- [[wasm-at-the-edge]] — Wasm's low-overhead execution as an edge energy efficiency technology

## Sources

- Green Software Foundation (2024). *What Is Green Software.* https://greensoftware.foundation/articles/what-is-green-software
- Green Software Foundation (2024). *Software Carbon Intensity (SCI) Specification.* https://sci-guide.greensoftware.foundation/
- Electricity Maps (2025). *Electricity Maps — Real-Time Carbon Intensity Data.* https://electricitymaps.com/
- Green Software Foundation (2024). *Carbon-Aware SDK (open source).* https://github.com/Green-Software-Foundation/carbon-aware-sdk
- Cloud Carbon Footprint (2024). *Cloud Carbon Footprint — Open Source Tool.* https://www.cloudcarbonfootprint.org/
- AWS (2024). *AWS Customer Carbon Footprint Tool.* https://aws.amazon.com/aws-cost-management/aws-customer-carbon-footprint-tool/
