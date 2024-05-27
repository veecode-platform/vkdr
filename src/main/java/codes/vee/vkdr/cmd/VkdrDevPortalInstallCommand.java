package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 61,
        description = "install VeeCode DevPortal (a free Backstage distro)")
class VkdrDevPortalInstallCommand implements Callable<Integer>  {

    @CommandLine.Option(names = {"-d","--domain"},
            defaultValue = "localhost",
            description = "DNS domain to use on generated ingress for DevPortal (default: localhost)")
    private String domain;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("devportal/install", domain);
    }
}
