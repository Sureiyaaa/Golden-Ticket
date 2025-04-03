using GoldenTicket.Entities;
using GoldenTicket.Models;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace GoldenTicket.Controllers
{
     [Route("api/[controller]")]
    public class GetDataController : Controller
    {
        [HttpGet("GetUsers")]
        public IActionResult GetUsersByRole()
        {
            try
            {
                var users = DBUtil.GetUsersByRole();
                return Ok(new {status = 200, message = "Users retrieved successfully", body = users});
            }
            catch (Exception err)
            {
                Console.WriteLine(err);
                return BadRequest(new {status = 400, message = "Invalid request, check your body format.", errorType = "invalid" });
            }
        }
        [HttpPost("FindUser")]
        public IActionResult FindUser([FromBody] User user)
        {
            try
            {
                var newUser = DBUtil.FindUser(user.UserID);
                return Ok(new {status = 200, message = $"Users retrieved successfully. {newUser.UserID}", body = newUser});
            }
            catch (Exception err)
            {
                Console.WriteLine(err);
                return BadRequest(new {status = 400, message = "Invalid request, check your body format.", errorType = "invalid" });
            }
        }
    }
}