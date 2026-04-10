using Godot;

namespace AI
{
	// Godot-facing adapter: delegates move selection to the shared AI engine.
	public partial class CreeperAI : Node
	{
		AIProgram aiProgram;
		public override void _Ready()
		{
			base._Ready();
			aiProgram = new AIProgram();
		}

		public string GetMoveHard(string boardString)
		{
			return aiProgram.GetMoveHard(boardString);
		}

		public string GetMoveEasy(string boardString)
		{
			return aiProgram.GetMoveEasy(boardString);
		}

		public string GetMveEasy(string boardString)
		{
			return aiProgram.GetMoveEasy(boardString);
		}

		public string GetNewBoardString(string boardString)
		{
			return aiProgram.GetNewBoardString(boardString);
		}
	}
}
