# Example Workflows

Real-world examples of using Academic Forge for various academic writing tasks.

## 📝 Example 1: Writing a Complete Research Paper

### Scenario
You're writing a computer science conference paper about a new algorithm.

### Workflow

**Step 1: Create Outline**
```
You: "Help me create an outline for a research paper about a novel sorting 
     algorithm with O(n log log n) complexity."

Claude: *Uses claude-scientific-skills*

Generated structure:
1. Abstract
2. Introduction
   - Motivation
   - Problem Statement
   - Contributions
3. Related Work
4. Methodology
   - Algorithm Design
   - Complexity Analysis
5. Experimental Results
6. Discussion
7. Conclusion
8. References
```

**Step 2: Design Experiments**
```
You: "I need to design experiments to validate my algorithm's performance."

Claude: *Uses AI-research-SKILLs*

Experiment design:
- Independent variables: input size, data distribution
- Dependent variables: execution time, memory usage
- Control: comparison with quicksort, mergesort, heapsort
- Methodology: repeated trials, statistical significance testing
```

**Step 3: Write and Format**
```
You: "Write the abstract based on this outline."

Claude: *Uses claude-scientific-skills for structure*
      *Uses humanizer for academic tone*

Generated LaTeX-formatted abstract with proper academic language.
```

---

## 🔬 Example 2: Literature Review for Thesis

### Scenario
PhD student conducting a systematic literature review.

### Workflow

**Step 1: Organize Papers**
```
You: "I have 50 papers on neural architecture search. Help me organize them 
     into a coherent literature review structure."

Claude: *Uses AI-research-SKILLs*

Suggested structure:
1. Taxonomy of approaches
2. Chronological development
3. Comparison of methodologies
4. Identified gaps
```

**Step 2: Synthesize Findings**
```
You: "Here are key points from each paper: [paste notes]. 
     Help me synthesize these into cohesive paragraphs."

Claude: *Uses humanizer for academic writing*
      *Uses claude-scientific-skills for proper citations*

Generated well-structured paragraphs with [Author, Year] citations.
```

**Step 3: Create Comparison Table**
```
You: "Create a LaTeX table comparing these approaches."

Claude: *Uses claude-scientific-skills*

Generated properly formatted LaTeX table with academic styling.
```

---

## 📊 Example 3: Data Analysis and Results Section

### Scenario
Analyzing experimental results for a biology paper.

### Workflow

**Step 1: Statistical Analysis**
```
You: "I have measurements from control and treatment groups: [data].
     What statistical tests should I use?"

Claude: *Uses AI-research-SKILLs*

Recommendations:
- Normality test (Shapiro-Wilk)
- Two-sample t-test or Mann-Whitney U (depending on normality)
- Effect size calculation (Cohen's d)
- Multiple comparison correction if needed
```

**Step 2: Write Results**
```
You: "The t-test gave p=0.023, Cohen's d=0.67. Write this in proper academic style."

Claude: *Uses claude-scientific-skills for formatting*
      *Uses humanizer for academic language*

Generated text:
"Treatment group showed significantly higher expression levels compared to 
control (t(48) = 2.34, p = 0.023, Cohen's d = 0.67), indicating a moderate 
effect size."
```

**Step 3: Create Figures**
```
You: "Suggest how to visualize this data."

Claude: *Uses AI-research-SKILLs*

Recommendations:
- Box plot showing distributions
- Bar chart with error bars
- Include individual data points as overlay
```

---

## ✍️ Example 4: Improving Existing Draft

### Scenario
You have a rough draft that needs academic polish.

### Workflow

**Step 1: Structure Check**
```
You: "Review this introduction section for proper academic structure: [paste text]"

Claude: *Uses claude-scientific-skills*

Feedback:
- Missing clear problem statement
- Background section too brief
- Contributions should be bulleted for clarity
- Smooth transition to next section needed
```

**Step 2: Tone Refinement**
```
You: "Make this paragraph more academic and professional: 
     'Our method is really good and beats all the other ones easily.'"

Claude: *Uses humanizer*

Improved:
"Our proposed approach demonstrates superior performance compared to existing 
state-of-the-art methods across multiple benchmark datasets, achieving 
significant improvements in accuracy while maintaining computational efficiency."
```

**Step 3: LaTeX Cleanup**
```
You: "Fix the LaTeX formatting in this equation section: [paste]"

Claude: *Uses claude-scientific-skills*

Fixed:
- Proper equation environment
- Consistent notation
- Appropriate alignment
- Numbered references
```

---

## 📚 Example 5: Grant Proposal

### Scenario
Writing a research grant proposal.

### Workflow

**Step 1: Research Plan**
```
You: "Help me structure the research methodology section of a grant proposal
     for studying machine learning fairness."

Claude: *Uses AI-research-SKILLs*

Structure:
1. Research Questions (specific, measurable)
2. Proposed Methods (detailed protocols)
3. Timeline with milestones
4. Expected Outcomes
5. Alternative approaches (risk mitigation)
```

**Step 2: Significance Statement**
```
You: "Write the 'Broader Impacts' section explaining why this research matters."

Claude: *Uses humanizer for persuasive academic writing*
      *Uses claude-scientific-skills for proper structure*

Generated compelling narrative with:
- Societal implications
- Potential applications
- Educational impact
- Dissemination plan
```

---

## 🎯 Example 6: Conference Paper Revision

### Scenario
Responding to reviewer comments.

### Workflow

**Reviewer Comment:**
> "The experimental methodology lacks detail about parameter selection."

**Your Response:**
```
You: "Reviewer says my methodology needs more detail on parameter selection.
     I used grid search with 5-fold cross-validation. Help me write a response."

Claude: *Uses AI-research-SKILLs for rigorous methodology description*
      *Uses humanizer for professional tone*

Generated response:
"We appreciate the reviewer's feedback. We have expanded Section 4.2 to 
include comprehensive details on parameter selection. Specifically, we employed 
grid search with 5-fold cross-validation across the following parameter ranges: 
[details]. The optimal parameters were selected based on mean validation 
accuracy with standard deviation < 0.02 across folds."
```

---

## 💡 Tips for Maximum Effectiveness

1. **Be Specific**: Instead of "improve this," say "make this sound more academic" or "format this as LaTeX"

2. **Chain Skills**: Let Claude use multiple skills in sequence:
   ```
   "Design an experiment [AI-research-SKILLs], 
    write it up [claude-scientific-skills], 
    and polish the language [humanizer]"
   ```

3. **Provide Context**: Give Claude your discipline, target journal/conference, and any specific style requirements

4. **Iterate**: Use the skills multiple times - first for structure, then refinement, then polish

5. **Combine with Other Tools**: Academic Forge works great alongside reference managers like Zotero

---

## 🎓 Success Stories

**PhD Student, Computer Science:**
> "Academic Forge cut my paper writing time in half. The LaTeX formatting alone 
> saved me hours of debugging."

**Postdoc, Biology:**
> "The research methodology skill helped me design better experiments with 
> proper controls I hadn't considered."

**Professor, Engineering:**
> "I use this with my whole lab. Students' first drafts now require much less 
> revision - the academic tone is already there."

---

## 📖 More Resources

- [Full Documentation](./README.md)
- [Quick Start Guide](./QUICKSTART.md)
- [Skill Attribution](./ATTRIBUTIONS.md)
- [Contributing](./CONTRIBUTING.md)

Have a great workflow to share? [Open a discussion](https://github.com/HughYau/academic-forge/discussions) and we'll add it here!
