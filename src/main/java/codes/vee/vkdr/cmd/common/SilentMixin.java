package codes.vee.vkdr.cmd.common;

import picocli.CommandLine.Option;
import picocli.CommandLine.ScopeType;

public class SilentMixin {
    @Option(names = {"--silent"},
            description = "Enable silent mode for raw output, only shows errors (default: false)",
            defaultValue = "false",
            scope = ScopeType.INHERIT)
    public boolean silent;
}
