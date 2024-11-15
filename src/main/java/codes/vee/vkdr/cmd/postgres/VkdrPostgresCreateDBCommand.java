package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "createdb", mixinStandardHelpOptions = true,
        description = "creates a new database, with an optional user/password as its owner",
        exitCodeOnExecutionException = ExitCodes.POSTGRES_INSTALL)
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
    description = "Store password in k8s secret")
    private boolean store_secret;

    @CommandLine.Option(names = {"--drop", "--drop-database", "--drop_database"},
            defaultValue = "false",
            description = "Drop (destroy) database if it exists")
    private boolean drop_database;

    @CommandLine.Option(names = {"--vault", "--create-vault", "--create_vault"},
            defaultValue = "false",
            description = "Create vault database engine config")
    private boolean create_vault;

    @CommandLine.Option(names = {"--vault-rotation", "--vault-rotation-schedule", "--vault_rotation_schedule"},
            defaultValue = "0 * * * SAT",
            description = "Vault secret rotation schedule (default: '0 * * * SAT')")
    private String vault_rotation_schedule;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("postgres/createdb", database_name, admin_password, user_name, password, String.valueOf(store_secret), String.valueOf(drop_database), String.valueOf(create_vault), vault_rotation_schedule);
    }
}
