package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "createdb", mixinStandardHelpOptions = true,
        description = "creates a new database, with an optional user/password as its owner",
        exitCodeOnExecutionException = 51)
public class VkdrPostgresCreateDBCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-d","--database"},
    required = true,
    description = "New database name")
    private String database_name;

    @CommandLine.Option(names = {"-u","--user"},
    defaultValue = "",
    description = "New user name")
    private String user_name;

    @CommandLine.Option(names = {"-p","--password"},
    defaultValue = "",
    description = "New user's password")
    private String password;

    @CommandLine.Option(names = {"-a","--admin", "--admin_password"},
    defaultValue = "",
    description = "Admin password")
    private String admin_password;

    @CommandLine.Option(names = {"-s","--store", "--store_secret"},
    defaultValue = "false",
    description = "Store password in secret")
    private boolean store_secret;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("postgres/createdb", database_name, admin_password, user_name, password, String.valueOf(store_secret));
    }
}
