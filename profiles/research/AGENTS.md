# Research Workspace Directive

## Core Principles
1. Prioritize reproducibility — every analysis should be rerunnable from raw data.
2. Document assumptions explicitly. If a conclusion depends on an unverified premise, flag it.
3. Prefer structured outputs (JSON, CSV, tables) over prose when presenting findings.

## Workflow Checklist
- Before starting analysis, confirm data sources are accessible and versioned.
- Use Python (3.11+) with uv for dependency management.
- Save intermediate results to avoid recomputation.
- Cite sources with URLs and access dates.

## Output Standards
- Summarize key findings in 3-5 bullet points at the top.
- Include methodology section explaining how results were obtained.
- Note limitations and confidence levels.
