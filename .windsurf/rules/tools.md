---
trigger: manual
---

# VKDR Tools
- The VKDR CLI uses tools it downloads when "vkdr init" is called. The "tools-versions.sh" script defined their versions to be downloaded.
- The "tools-versions.sh" can be updated running "generate-tools-versions.sh" during development (it detects new versions and updates "tools-versions.sh")
- When scripts use these tools it is **important** to user the paths defined by the env vars in "tools-paths.sh"
- So instead of "yq" scripts must use "$VKDR_YQ"
