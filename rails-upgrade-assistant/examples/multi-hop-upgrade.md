# Example: Multi-Hop Upgrade (Rails 7.0 → 8.1)

**Scenario:** User has Rails 7.0 and wants to upgrade to Rails 8.1

---

## User Request

```
User: "Help me upgrade from Rails 7.0 to 8.1"
```

---

## Claude's Response

```markdown
I'll help you upgrade from Rails 7.0 to 8.1. This requires a multi-hop sequential upgrade because **you cannot skip Rails versions**.

## ⚠️ Sequential Requirement

Rails upgrades MUST follow this exact sequence:
```
7.0.x → 7.1.x → 7.2.x → 8.0.x → 8.1.x
```

You'll need **4 separate upgrade hops**:
1. 7.0 → 7.1
2. 7.1 → 7.2
3. 7.2 → 8.0
4. 8.0 → 8.1

**Estimated Timeline:** 2-3 weeks total

---

## 📊 Upgrade Strategy Overview

| Hop | From | To | Difficulty | Time | Key Changes |
|-----|------|-----|-----------|------|-------------|
| 1 | 7.0 | 7.1 | ⭐⭐ Medium | 2-4 hours | MessageVerifier, Redis |
| 2 | 7.1 | 7.2 | ⭐⭐ Medium | 3-5 hours | PWA, browser checks |
| 3 | 7.2 | 8.0 | ⭐⭐⭐⭐ Very Hard | 1-2 weeks | Propshaft, Solid gems |
| 4 | 8.0 | 8.1 | ⭐ Easy | 2-4 hours | SSL config, bundler-audit |

**Total:** 2-3 weeks with testing between each hop

---

## 🎯 Recommended Approach

### Option A: Complete One Hop at a Time (Recommended)

**Process:**
1. Generate deliverables for Hop 1 (7.0 → 7.1)
2. Complete Hop 1 fully
3. Test thoroughly
4. Deploy to production
5. Wait 1 week to ensure stability
6. Then proceed to Hop 2

**Benefits:**
- ✅ Lower risk
- ✅ Easier to debug
- ✅ Can rollback easily
- ✅ Team can adapt gradually

### Option B: Generate All Hops Upfront

**Process:**
1. Generate deliverables for all 4 hops
2. Review complete upgrade path
3. Plan timeline
4. Execute hops sequentially

**Benefits:**
- ✅ See full scope upfront
- ✅ Better resource planning
- ✅ Identify major issues early

---

## 🤔 Which Approach Should I Use?

**Choose Option A if:**
- Team is small
- App is in production
- Can't afford long downtime
- Want to minimize risk

**Choose Option B if:**
- Need to plan timeline
- Want executive buy-in
- Large team can work in parallel
- Need comprehensive overview

---

Would you like me to:
1. **Generate all 4 hops now** (Option B)
2. **Start with just Hop 1** (Option A)

Your choice will determine how we proceed.
```

---

## If User Chooses Option A (One Hop)

```markdown
Great! Let's start with Hop 1: Rails 7.0 → 7.1

I've generated three comprehensive deliverables for Hop 1:

---

## 📋 HOP 1: Rails 7.0 → 7.1

### Deliverable #1: Upgrade Report
[Complete 50-page report for 7.0 → 7.1]

### Deliverable #2: Detection Script
[Bash script for 7.0 → 7.1 breaking changes]

### Deliverable #3: app:update Preview
[Config file changes for 7.0 → 7.1]

---

## 🚀 Next Steps for Hop 1

1. Review all deliverables
2. Run detection script
3. Complete upgrade
4. Test thoroughly
5. Deploy to staging
6. Deploy to production
7. **Wait 1 week** to ensure stability
8. Come back for Hop 2 (7.1 → 7.2)

**Important:** Do NOT proceed to Hop 2 until Hop 1 is 100% stable in production!
```

---

## If User Chooses Option B (All Hops)

```markdown
Perfect! I'll generate deliverables for all 4 hops so you can plan the complete journey.

---

## 📋 HOP 1: Rails 7.0 → 7.1

**Complexity:** ⭐⭐ Medium  
**Time:** 2-4 hours  
**Risk:** Medium

### Key Breaking Changes
- MessageVerifier API changes
- Redis configuration updates
- ActiveRecord query changes

### Deliverable #1: Upgrade Report
[Complete report for 7.0 → 7.1]

### Deliverable #2: Detection Script
[Bash script for 7.0 → 7.1]

### Deliverable #3: app:update Preview
[Config changes for 7.0 → 7.1]

---

## 📋 HOP 2: Rails 7.1 → 7.2

**Complexity:** ⭐⭐ Medium  
**Time:** 3-5 hours  
**Risk:** Medium

### Key Breaking Changes
- PWA support added
- Browser version checks
- ActionCable Redis defaults

### Deliverable #1: Upgrade Report
[Complete report for 7.1 → 7.2]

### Deliverable #2: Detection Script
[Bash script for 7.1 → 7.2]

### Deliverable #3: app:update Preview
[Config changes for 7.1 → 7.2 including PWA files]

---

## 📋 HOP 3: Rails 7.2 → 8.0

**Complexity:** ⭐⭐⭐⭐ Very Hard  
**Time:** 1-2 weeks  
**Risk:** High

### Key Breaking Changes
- **Propshaft replaces Sprockets** (asset pipeline)
- **Solid Cache, Queue, Cable** (new defaults)
- Significant configuration changes
- Breaking API changes

### Deliverable #1: Upgrade Report
[Complete report for 7.2 → 8.0 - EXTENSIVE]

### Deliverable #2: Detection Script
[Bash script for 7.2 → 8.0 - COMPREHENSIVE]

### Deliverable #3: app:update Preview
[Config changes for 7.2 → 8.0 - MAJOR CHANGES]

**⚠️ WARNING:** This is the most complex hop. Plan for 1-2 weeks and extensive testing.

---

## 📋 HOP 4: Rails 8.0 → 8.1

**Complexity:** ⭐ Easy  
**Time:** 2-4 hours  
**Risk:** Low

### Key Breaking Changes
- SSL configuration (assume_ssl)
- bundler-audit integration

### Deliverable #1: Upgrade Report
[Complete report for 8.0 → 8.1]

### Deliverable #2: Detection Script
[Bash script for 8.0 → 8.1]

### Deliverable #3: app:update Preview
[Config changes for 8.0 → 8.1]

---

## 📅 Recommended Timeline

### Week 1: Hop 1 (7.0 → 7.1)
- Day 1-2: Upgrade and test
- Day 3: Deploy to staging
- Day 4-5: Staging validation
- Day 6: Deploy to production
- Day 7: Monitor

### Week 2: Stabilization
- Monitor Hop 1 in production
- Fix any issues
- Ensure 100% stability

### Week 3: Hop 2 (7.1 → 7.2)
- Day 1-2: Upgrade and test
- Day 3: Deploy to staging
- Day 4-5: Staging validation
- Day 6: Deploy to production
- Day 7: Monitor

### Week 4: Stabilization
- Monitor Hop 2 in production

### Weeks 5-6: Hop 3 (7.2 → 8.0) - MAJOR
- Week 5: Upgrade, extensive testing
- Week 6: Staging, production, monitoring

### Week 7: Stabilization
- Monitor Hop 3 in production (CRITICAL)

### Week 8: Hop 4 (8.0 → 8.1)
- Days 1-2: Upgrade and test
- Days 3-4: Deploy and monitor

**Total:** 8 weeks (2 months) for complete journey

---

## 🎯 Critical Success Factors

1. **Complete Each Hop Fully**
   - Don't start Hop 2 until Hop 1 is stable in production

2. **Test Between Hops**
   - 100% test pass rate before moving forward

3. **Monitor Closely**
   - Watch logs for 1 week after each hop

4. **Plan for Hop 3**
   - This is the big one (7.2 → 8.0)
   - Allocate 2 weeks
   - Consider hiring Rails expert for this hop

5. **Keep Team Informed**
   - Share timeline with stakeholders
   - Set expectations for 2-month project

---

## 🚀 Your Next Steps

1. **Review all 4 hops** above
2. **Choose your start date**
3. **Allocate 2 months** in your roadmap
4. **Start with Hop 1** when ready
5. **Come back** after each hop for guidance

Would you like me to explain any hop in more detail?
```

---

## Key Principles for Multi-Hop Upgrades

1. **Never Skip Versions** - Always sequential
2. **Complete Each Hop Fully** - Don't rush
3. **Test Thoroughly** - 100% pass rate between hops
4. **Monitor in Production** - 1 week stability
5. **Plan for Hop 3** - It's the hardest (7.2 → 8.0)

---

**Related Files:**
- Reference: `reference/multi-hop-strategy.md`
- All workflows: `workflows/*.md`
- Examples: Other examples in `examples/`
