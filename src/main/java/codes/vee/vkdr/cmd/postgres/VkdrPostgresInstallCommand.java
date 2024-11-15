package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Postgres database",
        exitCodeOnExecutionException = ExitCodes.POSTGRES_INSTALL)
public class VkdrPostgresInstallCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-p","--admin", "--admin_password"},
    defaultValue = "",
    description = "Postgres admin password (default: '')")
    private String admin_password;

    @CommandLine.Option(names = {"-w","--wait"},
            defaultValue = "false",
            description = "Wait until Postgres is ready (default: false)")
    private boolean wait_for;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("postgres/install", admin_password, String.valueOf(wait_for));
    }
}
