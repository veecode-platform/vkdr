package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Postgres database",
        exitCodeOnExecutionException = 51)
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
