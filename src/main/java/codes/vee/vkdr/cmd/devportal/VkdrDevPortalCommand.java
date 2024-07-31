package codes.vee.vkdr.cmd.devportal;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "devportal", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 60,
        description = "install/remove VeeCode DevPortal (a free Backstage distro)",
        subcommands = {VkdrDevPortalInstallCommand.class})
public class VkdrDevPortalCommand {

    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove VeeCode DevPortal",
            exitCodeOnExecutionException = 62)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("devportal/remove");
    }

    @CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
            description = "explain VeeCode DevPortal formulas",
            exitCodeOnExecutionException = 63)
    int explain() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("devportal/explain");
    }
}
