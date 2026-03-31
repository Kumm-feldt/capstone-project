using Godot;

namespace AI
{
	// Godot-facing adapter: delegates move selection to the shared AI engine.
	public partial class CreeperAI : Node
	{
		public string GetMove(string boardString)
		{
			var aiProgram = new AIProgram();
			return aiProgram.GetMove(boardString);
		}

		public string GetNewBoardString(string boardString)
		{
			var aiProgram = new AIProgram();
			return aiProgram.GetNewBoardString(boardString);
		}
	}
}
