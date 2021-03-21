import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.FileOutputStream
import java.nio.file.Paths
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

fun main(args: Array<String>) {
    for (arg in args) {
        println(arg)
    }
    val prefix = args[0]
    val output = args[1]
    val jars = args.sliceArray(2..args.lastIndex)

    val entryNames = mutableSetOf<String>()

    ZipOutputStream(BufferedOutputStream(FileOutputStream(output))).use { out ->
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
                        val newEntry = ZipEntry(Paths.get(prefix, entry.name).toString())
                        out.putNextEntry(newEntry)
                        inputStream.copyTo(out, 1024)
                    }
                }
            }
        }
    }

}