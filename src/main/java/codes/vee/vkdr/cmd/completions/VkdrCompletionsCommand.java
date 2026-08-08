package codes.vee.vkdr.cmd.completions;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "completions", aliases = {"completion"}, mixinStandardHelpOptions = true,
        exitCodeOnExecutionException = ExitCodes.COMPLETIONS_BASE,
        description = "generate and install shell TAB-completion for vkdr (bash, zsh)",
        subcommands = {
                VkdrCompletionsBashCommand.class,
                VkdrCompletionsZshCommand.class,
                VkdrCompletionsInstallCommand.class,
                VkdrCompletionsUninstallCommand.class,
                VkdrCompletionsStatusCommand.class,
                VkdrCompletionsExplainCommand.class})
public class VkdrCompletionsCommand {
}
