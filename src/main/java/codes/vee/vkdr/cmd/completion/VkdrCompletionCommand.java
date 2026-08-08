package codes.vee.vkdr.cmd.completion;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "completion", mixinStandardHelpOptions = true,
        exitCodeOnExecutionException = ExitCodes.COMPLETION_BASE,
        description = "generate and install shell TAB-completion for vkdr (bash, zsh)",
        subcommands = {
                VkdrCompletionBashCommand.class,
                VkdrCompletionZshCommand.class,
                VkdrCompletionInstallCommand.class,
                VkdrCompletionUninstallCommand.class,
                VkdrCompletionStatusCommand.class,
                VkdrCompletionExplainCommand.class})
public class VkdrCompletionCommand {
}
