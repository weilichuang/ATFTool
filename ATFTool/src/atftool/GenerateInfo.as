package atftool
{

	public class GenerateInfo
	{
		public var sourceDir:String; //源
		public var exportDir:String; //目标
		public var platform:String; //平台
		public var compress:Boolean; //是否压缩
		public var mips:Boolean; //是否启用
		public var quality:int; //质量

		/**
		 * 创建缩略图
		 */
		public var createMips:Boolean;
		public var mipWidth:int;
		public var mipHeight:int;
		public var mipExt:String;
		
		/**
		 * 导出后缀名
		 */
		public var exportExt:String;

		public function GenerateInfo()
		{
		}
	}
}
