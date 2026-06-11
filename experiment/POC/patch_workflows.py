import os
import glob

workflow_dir = "/Users/oktay.copurlu/.ai-shared/experiment/POC/copy-to-on-frontend/.github/workflows"
files = glob.glob(f"{workflow_dir}/phase-*.md")

checkout_step = """
  - name: Checkout on-frontend repository (POC)
    uses: actions/checkout@v4
    with:
      repository: 'onrunning/on-frontend'
      token: ${{ secrets.ON_FRONTEND_PAT }}
      path: 'on-frontend-workspace'
"""

instruction = """
> [!IMPORTANT]
> **POC ENVIRONMENT:** You are running in the `ai-shared` repository, but your target is `on-frontend`.
> The `on-frontend` repository has been checked out into the `./on-frontend-workspace` directory.
> **All code analysis and modifications MUST be done inside `./on-frontend-workspace`.**
"""

for filepath in files:
    with open(filepath, 'r') as f:
        content = f.read()
    
    # 1. Update the header comment
    content = content.replace(
        "# READY TO COPY into onrunning/on-frontend/.github/workflows/. Then run: gh aw compile",
        "# POC WORKFLOW: Runs in ai-shared, targets onrunning/on-frontend. Then run: gh aw compile"
    )
    content = content.replace(
        "# Place in onrunning/on-frontend/.github/workflows/ once adopted, then run: gh aw compile",
        "# POC WORKFLOW: Runs in ai-shared, targets onrunning/on-frontend. Then run: gh aw compile"
    )

    # 2. Add checkout step if 'steps:' exists, or create it.
    if "steps:" in content and "Checkout on-frontend repository (POC)" not in content:
        content = content.replace("steps:\n", "steps:\n" + checkout_step)
    elif "steps:" not in content and "Checkout on-frontend repository (POC)" not in content:
        # If no steps section, we can inject it before post-steps or tools
        if "post-steps:" in content:
            content = content.replace("post-steps:\n", "steps:\n" + checkout_step + "\npost-steps:\n")
        else:
            content = content.replace("tools:\n", "steps:\n" + checkout_step + "\ntools:\n")
            
    # 3. Add the agent instruction in the markdown body
    if "## Phase work" in content and instruction not in content:
        content = content.replace("## Phase work\n", "## Phase work\n" + instruction + "\n")

    with open(filepath, 'w') as f:
        f.write(content)

print("Patching complete.")
