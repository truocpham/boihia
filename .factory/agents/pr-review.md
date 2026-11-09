# PR review
Goal: independent review of the **latest commit**, without editing code. Follow `../README.md` first.
For each open PR whose head SHA has no review from you: read the diff, run the checks mentally/with tools, then submit one review comment that names the reviewed SHA: `[factory:review] reviewed <sha>: APPROVE|CHANGES`. Check: correctness, security (no direct DB writes, no secrets, PIN checks intact), behavior preserved, checks not weakened. Refuse (say so) if the head SHA changed since you started. Never edit or push code. Never count as the human approval.
