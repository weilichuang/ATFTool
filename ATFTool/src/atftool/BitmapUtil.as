package atftool
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.PNGEncoderOptions;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class BitmapUtil
	{

		private static var sizes:Vector.<int> = Vector.<int>([2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096]);

		/**
		 * 图像尺寸自动纠正为2幂
		 * @param file			文件
		 * @param toSquare		是否转换为方形
		 * @param converCallBack	转换完毕的回掉
		 * @param logCallBack		输出日志回掉
		 */
		public static function converBitmapToPowerOf2(file:File, converCallBack:Function, logCallBack:Function):void
		{
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);

			var bytes:ByteArray = new ByteArray();
			fs.readBytes(bytes);
			fs.close();
			getBitmapData(bytes, getBitmapCallBack);

			function getBitmapCallBack(bitmapdata:BitmapData):void
			{
				var rect:Rectangle = getPowerOf2Rect(bitmapdata.width, bitmapdata.height);

				if (rect.width != bitmapdata.width || rect.height != bitmapdata.height)
				{
					logCallBack("图片边长转换为2幂...\n");

					var temp:BitmapData = new BitmapData(rect.width, rect.height, true, 0);
					temp.copyPixels(bitmapdata, temp.rect, new Point(0, 0));

					var data:ByteArray = temp.encode(temp.rect, new PNGEncoderOptions(true));

					fs = new FileStream();
					fs.open(file, FileMode.WRITE);
					fs.writeBytes(data);
					fs.close();
				}
				else
				{
					bytes = null;
				}
				converCallBack(bytes, file);
			}
		}

		public static function scaleBitmap(bitmapData:BitmapData, newWidth:int, newHeight:int):BitmapData
		{
			var sx:Number = newWidth / bitmapData.width;
			var sy:Number = newHeight / bitmapData.height;

			var result:BitmapData = new BitmapData(newWidth, newHeight, bitmapData.transparent, 0x0);
			var matrix:Matrix = new Matrix();
			matrix.scale(sx, sy);
			result.draw(bitmapData, matrix, null, null, null, true);
			return result;
		}


		/**
		 * 根据bytearray获取
		 * @param bytes
		 * @param callBack
		 *
		 */
		public static function getBitmapData(bytes:ByteArray, callBack:Function):void
		{
			var loader:Loader = new Loader();
			loader.loadBytes(bytes);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderComplete);

			function loaderComplete(e:Event):void
			{
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loaderComplete);
				callBack((loader.contentLoaderInfo.content as Bitmap).bitmapData);
			}
		}

		/**
		 * 根据宽高获取一个两边边长都是2幂的矩形
		 * @param width		原始宽度
		 * @param height	原始高度
		 *
		 */
		public static function getPowerOf2Rect(width:int, height:int):Rectangle
		{

			width = getSize(width);
			height = getSize(height);

			return new Rectangle(0, 0, width, height);

			function getSize(value:int):int
			{
				var length:int = sizes.length;
				for (var i:int = 0; i < length - 1; i++)
				{
					if (value == sizes[i])
					{
						return value;
					}

					if (value > sizes[i] && value < sizes[i + 1])
					{
						return sizes[i + 1];
					}
				}
				return value;
			}
		}
		
		/**
		 * Returns true if the number is a power of 2 (2,4,8,16...)
		 * 
		 * A good implementation found on the Java boards. note: a number is a power
		 * of two if and only if it is the smallest number with that number of
		 * significant bits. Therefore, if you subtract 1, you know that the new
		 * number will have fewer bits, so ANDing the original number with anything
		 * less than it will give 0.
		 * 
		 * @param number
		 *            The number to test.
		 * @return True if it is a power of two.
		 */
		public static function isPowerOfTwo(number:int):Boolean
		{
			return (number > 0) && (number & (number - 1)) == 0;
		}
	}
}
