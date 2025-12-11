package codes.vee.vkdr.cmd.openldap;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove OpenLDAP",
        exitCodeOnExecutionException = ExitCodes.OPENLDAP_REMOVE)
public class VkdrOpenldapRemoveCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-d", "--delete"}, description = "delete the associated PVC (data-openldap-0)")
    private boolean deletePvc;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("openldap/remove", String.valueOf(deletePvc));
    }
}
