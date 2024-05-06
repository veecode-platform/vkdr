package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;
import picocli.CommandLine.Option;
import java.io.IOException;

@Component
@CommandLine.Command(name = "postgres", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 50,
        description = "install/remove Postgres database",
        subcommands = {VkdrPostgresInstallCommand.class, VkdrPostgresCreateDBCommand.class})
class VkdrPostgresCommand {

    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove Postgres database",
            exitCodeOnExecutionException = 52)
    int remove(@Option(names = {"-d","--delete", "--delete_storage", "--delete-storage"},
                defaultValue = "false",
                description = "delete postgres storage too after removal (default: false)")
                boolean delete_storage) throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("postgres/remove", String.valueOf(delete_storage));
    }
    @CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
            description = "explain Postgres install formulas",
            exitCodeOnExecutionException = 53)
    int explain() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("postgres/explain");
    }

}
