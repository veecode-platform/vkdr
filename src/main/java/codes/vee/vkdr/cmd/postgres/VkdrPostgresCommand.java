package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "postgres", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.POSTGRES_BASE,
        description = "manage Postgres database",
        subcommands = {
            VkdrPostgresCreateDBCommand.class,
            VkdrPostgresDropDBCommand.class,
            VkdrPostgresExplainCommand.class,
            VkdrPostgresInstallCommand.class,
            VkdrPostgresListDBsCommand.class,
            VkdrPostgresPingDBCommand.class,
            VkdrPostgresRemoveCommand.class
        })
public class VkdrPostgresCommand {
}
