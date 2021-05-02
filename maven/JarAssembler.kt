import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.*
import java.util.concurrent.Callable
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream
import kotlin.system.exitProcess


@Command(name = "jar-assembler", mixinStandardHelpOptions = true)
class JarAssembler : Callable<Unit> {

    @Option(names = ["--output"], required = true)
    lateinit var output_file: File

    @Option(names = ["--prefix"])
    lateinit var prefix: String

    @Option(names = ["--group-id"])
    var groupId = ""

    @Option(names = ["--artifact-id"])
    var artifactId = ""

    @Option(names = ["--pom-file"])
    var pomFile: File? = null

    @Option(names = ["--jars"], split = ";")
    lateinit var jars: Array<File>

    val entryNames = mutableSetOf<String>()

    override fun call() {
        ZipOutputStream(BufferedOutputStream(FileOutputStream(output_file))).use { out ->
            if (pomFile != null) {
                val pomFileEntry = ZipEntry("META-INF/maven/${groupId}/${artifactId}/pom.xml")
                out.putNextEntry(pomFileEntry)
                out.write(pomFile!!.readBytes())
            }
            for (jar in jars) {
                ZipFile(jar).use { jarZip ->
                    jarZip.entries().asSequence().forEach { entry ->
                        if (entry.name.contains("META-INF")) {
                            return@forEach
                        }
                        if (entryNames.contains(entry.name)) {
                            return@forEach
                        }
                        entryNames.add(entry.name)
                        BufferedInputStream(jarZip.getInputStream(entry)).use { inputStream ->
                            var name = entry.name
                            if (!name.startsWith(prefix)) {
                                name = prefix + name;
                            }
                            val newEntry = ZipEntry(name)
                            out.putNextEntry(newEntry)
                            inputStream.copyTo(out, 1024)
                        }
                    }
                }
            }
        }
    }
}

fun main(args: Array<String>): Unit = exitProcess(CommandLine(JarAssembler()).execute(*args))