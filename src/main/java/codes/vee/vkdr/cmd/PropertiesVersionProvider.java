package codes.vee.vkdr.cmd;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
class PropertiesVersionProvider implements CommandLine.IVersionProvider {
    @Value("${vkdr.version}")
    private String vkdrVersion;

    @Override
    public String[] getVersion() {
        if (vkdrVersion == null) {
            return new String[]{"No version information available"};
        }
        return new String[]{
                "VKDR: " + vkdrVersion,
                "Spring Boot: ${springBootVersion}",
                "Picocli: " + CommandLine.VERSION,
                "JVM: ${java.version} (${java.vendor} ${java.vm.name} ${java.vm.version})",
                "OS: ${os.name} ${os.version} ${os.arch}"
        };
    }
}
