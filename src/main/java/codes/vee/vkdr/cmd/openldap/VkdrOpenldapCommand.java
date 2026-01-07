package codes.vee.vkdr.cmd.openldap;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "openldap", mixinStandardHelpOptions = true, 
        exitCodeOnExecutionException = ExitCodes.OPENLDAP_BASE,
        description = "manage openldap service",
        subcommands = {
            VkdrOpenldapExplainCommand.class,
            VkdrOpenldapInstallCommand.class,
            VkdrOpenldapRemoveCommand.class
        })
public class VkdrOpenldapCommand {
}
