import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.lang.RuntimeException
import java.nio.ByteBuffer
import java.nio.charset.Charset
import java.nio.file.Path
import java.nio.file.Paths
import java.util.*
import java.util.concurrent.Callable
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream
import kotlin.system.exitProcess


@Command(name = "jar-assembler", mixinStandardHelpOptions = true)
class JarAssembler : Callable<Unit> {
    val javaPackageRegex = Regex("package\\s+([a-zA_Z_][\\.\\w]*);")

    @Option(names = ["--output"], required = true)
    lateinit var output_file: File

    @Option(names = ["--group-id"])
    var groupId = ""

    @Option(names = ["--artifact-id"])
    var artifactId = ""

    @Option(names = ["--pom-file"])
    var pomFile: File? = null

    @Option(names = ["--jars"], split = ";")
    lateinit var jars: Array<File>

    private val entryNames = mutableSetOf<String>()
    val entries = HashMap<String, ByteArray>()

    /**
     * For path "a/b/c.java" inserts "a/" and "a/b/ into `entries`
     */
    private fun addDirectories(path: Path) {
        for (i in path.nameCount-1 downTo 1) {
            val subPath = path.subpath(0, i).toString() + "/"
            entries[subPath] = ByteArray(0)
        }
    }

    override fun call() {
        ZipOutputStream(BufferedOutputStream(FileOutputStream(output_file))).use { out ->
            if (pomFile != null) {
                val pomPath = "META-INF/maven/${groupId}/${artifactId}/pom.xml"
                entries[pomPath] = pomFile!!.readBytes()
                addDirectories(Paths.get(pomPath))
            }
            for (jar in jars) {
                ZipFile(jar).use { jarZip ->
                    jarZip.entries().asSequence().forEach { entry ->
                        if (entry.name.contains("META-INF")) {
                            // pom.xml will be added by us
                            return@forEach
                        }
                        if (entryNames.contains(entry.name)) {
                            throw RuntimeException("duplicate entry in the JAR: ${entry.name}")
                        }
                        if (entry.isDirectory) {
                            // needed directories would be added by us
                            return@forEach
                        }
                        entryNames.add(entry.name)
                        BufferedInputStream(jarZip.getInputStream(entry)).use { inputStream ->
                            val sourceFileBytes = inputStream.readBytes()
                            val sourceFile = sourceFileBytes.toString(Charset.forName("UTF-8"))
                            var resultLocation = entry.name
                            // files in source JARs are moved according to their `package` statement
                            if (entry.name.endsWith(".java")) {
                                val sourceFileName = Paths.get(entry.name).fileName.toString()
                                val sourceFilePackage = javaPackageRegex.find(sourceFile)?.groups?.get(1)?.value ?: throw RuntimeException("could not obtain package of ${entry.name}")
                                resultLocation = "${sourceFilePackage.replace(".", "/")}/$sourceFileName"
                            }
                            entries[resultLocation] = sourceFileBytes
                            addDirectories(Paths.get(resultLocation))
                        }
                    }
                }
            }
            entries.keys.sorted().forEach {
                val newEntry = ZipEntry(it)
                out.putNextEntry(newEntry)
                out.write(entries[it]!!)
            }
        }
    }
}

fun main(args: Array<String>): Unit = exitProcess(CommandLine(JarAssembler()).execute(*args))
