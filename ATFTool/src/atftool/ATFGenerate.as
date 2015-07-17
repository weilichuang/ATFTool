package atftool
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.PNGEncoderOptions;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	

	public class ATFGenerate extends EventDispatcher
	{
		public static const EVENT_GENERATE_COMPLETE:String = "EVENT_GENERATE_COMPLETE";

		private var file:File;
		private var info:GenerateInfo;
		private var isJPG:Boolean = false;

		private var loader:Loader;

		private var nativeProcess:NativeProcess;

		private var logHandle:Function;

		private var executableFile:File;

		private var files:Vector.<File>;
		private var fileIndex:int = 0;

		public function ATFGenerate()
		{
			this.files = new Vector.<File>();
		}

		public function generate(file:File, info:GenerateInfo, logHandle:Function):void
		{
			this.files.length = 0;
			this.fileIndex = 0;

			this.file = file;
			this.info = info;
			this.logHandle = logHandle;

			this.isJPG = file.extension.toLocaleLowerCase() == "jpg" || file.extension.toLocaleLowerCase() == "jpeg";

			if (this.info.createMips || this.isJPG)
			{
				var bytes:ByteArray = readBytes(file);

				if (loader == null)
					loader = new Loader();
				loader.loadBytes(bytes);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderComplete);
			}
			else
			{
				this.files.push(file);
				createAtf(this.files[this.fileIndex++]);
			}
		}

		private function createAtf(file:File):void
		{
			var sourceFilePath:String = file.nativePath;
			var exportFilePath:String = sourceFilePath.replace(this.info.sourceDir, this.info.exportDir);
			exportFilePath = exportFilePath.replace("." + file.extension, ".atf");

			if (executableFile == null)
			{
				if (OSUtil.isMac())
				{
					executableFile = File.applicationDirectory.resolvePath("png2atf");
				}
				else if (OSUtil.isWindows())
				{
					executableFile = File.applicationDirectory.resolvePath("png2atf.exe");
				}
			}


			var params:Vector.<String> = new Vector.<String>();
			params.push("-c");

			if (info.platform != "")
			{
				params.push(info.platform);
			}

			if (info.compress)
			{
				params.push("-r");
			}

			params.push("-q");
			params.push(info.quality);

			if (info.mips)
			{
				params.push("-n");
				params.push("0,");
			}
			else
			{
				params.push("-n");
				params.push("0,0");
			}

			params.push("-i");
			params.push(sourceFilePath);
			params.push("-o");
			params.push(exportFilePath);

			var workingDirectory:File = new File(this.info.sourceDir);
			var startUpInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startUpInfo.workingDirectory = workingDirectory;
			startUpInfo.arguments = params;
			startUpInfo.executable = executableFile;

			if (nativeProcess == null)
			{
				nativeProcess = new NativeProcess();
				nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, onExit);
				nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onData);
				nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onError);
			}

			try
			{
				nativeProcess.start(startUpInfo);
			}
			catch (error:Error)
			{
				logHandle(error.getStackTrace() + "\n");
			}
		}

		private function onExit(e:NativeProcessExitEvent):void
		{
			//删除生成的png文件
			var newFile:File;
			if (this.isJPG)
			{
				newFile = this.files[this.fileIndex - 1];
				if (newFile.exists)
					newFile.deleteFile();
			}
			//或者缩略图
			else if (this.fileIndex == 2)
			{
				newFile = this.files[this.fileIndex - 1];
				if (newFile.exists)
					newFile.deleteFile();
			}

			if (this.fileIndex == this.files.length)
			{
				dispatchEvent(new Event(EVENT_GENERATE_COMPLETE));
				return;
			}

			createAtf(this.files[this.fileIndex++]);
		}

		private function onData(e:ProgressEvent):void
		{
			logHandle(nativeProcess.standardOutput.readUTFBytes(nativeProcess.standardOutput.bytesAvailable));
		}

		private function onError(e:ProgressEvent):void
		{
			logHandle(nativeProcess.standardError.readUTFBytes(nativeProcess.standardError.bytesAvailable));
		}

		private function loaderComplete(e:Event):void
		{
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loaderComplete);
			var bitmapData:BitmapData = (loader.contentLoaderInfo.content as Bitmap).bitmapData;

			var nativePath:String = file.nativePath;
			var ext:String = file.extension;
			var path:String;
			//生成对应的png文件
			if (this.isJPG)
			{
				path = nativePath.substr(0, nativePath.lastIndexOf(ext)) + "png";

				var data:ByteArray = bitmapData.encode(bitmapData.rect, new PNGEncoderOptions(true));
				this.file = writeBytes(path, data);
			}
			
			this.files.push(file);

			if (this.info.createMips)
			{
				var scaleBitmapData:BitmapData = BitmapUtil.scaleBitmap(bitmapData, this.info.mipWidth, this.info.mipHeight);

				var scaleData:ByteArray = scaleBitmapData.encode(scaleBitmapData.rect, new PNGEncoderOptions(true));

				path = nativePath.substr(0, nativePath.lastIndexOf("." + ext)) + this.info.mipExt + ".png";

				var mipFile:File = writeBytes(path, scaleData);

				this.files.push(mipFile);
			}

			this.fileIndex = 0;
			createAtf(this.files[this.fileIndex++]);
		}

		private function readBytes(file:File):ByteArray
		{
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);

			var bytes:ByteArray = new ByteArray();
			fs.readBytes(bytes);
			fs.close();

			return bytes;
		}

		private function writeBytes(filePath:String, bytes:ByteArray):File
		{
			var newFile:File = new File(filePath);

			var fs:FileStream = new FileStream();
			fs.open(newFile, FileMode.WRITE);
			fs.writeBytes(bytes);
			fs.close();

			return newFile;
		}
	}
}
